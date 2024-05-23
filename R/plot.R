make_quantile_df <- function(vals, probs) {

  stats::quantile(vals, probs=probs, na.rm = TRUE) |>
    as.list() |>
    tibble::as_tibble() |>
    tidyr::pivot_longer(dplyr::everything()) |>
    dplyr::mutate(name_lag = dplyr::lag(name),
                  val_lag = dplyr::lag(value)) |>
    dplyr::filter(!is.na(name_lag)) |>
    dplyr::transmute(
      name = glue::glue("{name_lag}-{name}"),
      name = dplyr::case_match(
        name,
        "0%-2%" ~ "0-2 (D4)",
        "2%-5%" ~ "2-5 (D3)",
        "5%-10%" ~ "5-10 (D2)",
        "10%-20%" ~ "10-20 (D1)",
        "20%-30%" ~ "20-30 (D0)",
        "30%-70%" ~ "30-70 (Normal)",
        "70%-80%" ~ "70-80 (W0)",
        "80%-90%" ~ "80-90 (W1)",
        "90%-95%" ~ "90-95 (W2)",
        "95%-98%" ~ "95-98 (W3)",
        "98%-100%" ~ "98-100 (W4)"
      ),
      ymin = val_lag,
      ymax = value
    )
}
#' Create a plot of current streamflow conditions, with the climatology of the
#' last 30 years plotted using the USDM color palette.
#'
#' @param data A `tibble` returned by [get_discharge()]
#' @param STANAME The USGS station name for the station you are plotting
#' @param STAID The USGS station ID for the station that is being plotted.
#' @param ... If `out_dir` is specified as an additional argument, the plot
#' will be saved out to `out_dir/{STAID}_discharge.png`
#'
#' @return A `ggplot` object of the plot. If `out_dir` is specified, the output filename is returned.
#' @export
#'
#' @examples
#' discharge <-  get_discharge("05014500")
#' make_climatology_plot(
#'   discharge,
#'   "Swiftcurrent Creek at Many Glacier MT",
#'   "05014500"
#')
make_climatology_plot <- function(data, STANAME, STAID, ...) {
  USDM_colors <-
    c(
      `0-2 (D4)` = "#730000",
      `2-5 (D3)` = "#E60000",
      `5-10 (D2)` = "#FFAA00",
      `10-20 (D1)` = "#FCD37F",
      `20-30 (D0)` = "#FFFF00",
      `30-70 (Normal)` = "white",
      `70-80 (W0)` = "#9DFF44",
      `80-90 (W1)` = "#22FFFF",
      `90-95 (W2)` = "#1197FE",
      `95-98 (W3)` = "#1100FF",
      `98-100 (W4)` = "#0A0099"
    )

  data = tibble::tibble(data)

  this_year = lubridate::today() |> lubridate::year()

  ribbons <- data |>
    dplyr::group_by(date = lubridate::yday(date)) |>
    dplyr::summarise(
      ribbons = list(make_quantile_df(
        val, c(0.00, 0.02, 0.05, 0.10, 0.20, 0.30, 0.70, 0.80, 0.90, 0.95, 0.98, 1.00)
      ))
    ) |>
    tidyr::unnest(ribbons) |>
    dplyr::mutate(
      date = as.Date(date-1, origin = glue::glue("{this_year}-01-01"))
    )

  out <- data |>
    dplyr::filter(lubridate::year(date) == this_year)

  other_args = list(...)

  plt <- ggplot2::ggplot() +
    ggplot2::geom_ribbon(
      data = ribbons,
      mapping = ggplot2::aes(x=date, ymin=ymin, ymax=ymax, fill=name),
      alpha = 0.5
    ) +
    ggplot2::geom_line(
      data = out,
      ggplot2::aes(x=date, y=val, linewidth = "Observed"),
      color = "black",
      lineend = "round") +
    ggplot2::scale_fill_manual(
      values = USDM_colors,
      breaks = rev(names(USDM_colors)),
      labels = rev(names(USDM_colors))
    ) +
    ggplot2::scale_linewidth_manual(
      name = paste0("Present\nConditions"),
      values = 1.5,
      guide = ggplot2::guide_legend(order = 3)
    ) +
    ggplot2::theme_bw(base_size = 12) +
    ggplot2::labs(x='', y='Discharge [cfs]',
         fill=glue::glue("Past Conditions\n(Percentiles)\n{this_year-30}-{this_year}"),
         title=glue::glue("USGS Gauge {STAID} (", max(out$date) %>% 
                            format(., format = '%m-%d-%Y') %>%
                            as.character(), ")\n{STANAME}")) +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold", hjust = 0.5)) +
    ggplot2::scale_y_log10(labels = label_comma()) 

  if ("out_dir" %in% names(other_args)) {
    out_dir = other_args[['out_dir']]
    if (!is.null(out_dir)) {
      out_name = file.path(
        out_dir,
        glue::glue("{STAID}_discharge.png")
      )

      ggplot2::ggsave(out_name, plt, bg="white", width = 8, height=5)
      return(out_name)
    }
  }
  return(plt)
}
