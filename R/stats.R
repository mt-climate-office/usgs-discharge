calc_range_ntile <- function(data, n_days) {
  max_date = max(data$date)
  previous_dates = max_date - 0:(n_days - 1)
  purrr::map(0:29, \(x) {
    date_filter <- previous_dates - lubridate::years(x)
    data <- data |>
      dplyr::filter(date %in% date_filter)

    tibble::tibble(
        val = mean(data$val, na.rm = TRUE),
        date = max(date_filter)
      )
  }) |>
    dplyr::bind_rows() |>
    dplyr::mutate(
      pct = dplyr::percent_rank(val)
    ) |>
    dplyr::filter(date == max_date) |>
    dplyr::pull(pct) * 100
}

pal <- leaflet::colorBin(
  colorRamp(
    c("#730000", "#E60000", "#FFAA00", "#FCD37F", "#FFFF00", "#FFFFFF", '#82FCF9', '#32E1FA', '#325CFE', '#4030E3', '#303B83'),
    interpolate = "linear"
  ),
  domain = 0:100,
  bins = c(0, 2, 5, 10, 20, 30, 70, 80, 90, 95, 98, 100),
  na.color = "#000000"
)


#' Calculate current, 7-, 14- and 28- day percentiles of discharge at USGS stations.
#' Uses `furrr` to process statistics in parallel. By default,
#' `furrr` uses a sequential plan to get discharge, but you can specify a multisession
#' plan by running `future::plan(future::multisession, workers = 5)` before running the code.
#'
#' @param discharge The `sf` object returned by [get_discharge_shp()].
#'
#' @return The same `sf` as was input, but with a `time` column corresponding to
#' the time period of aggregation, a `value` column corresponding to the percentile
#' value of the observation, and a `fillColor` column corresponding to the USDM color
#' palette for the percentile.
#' @export
#'
#' @examples
#' \dontrun{
#' stations = get_gauges()
#' discharge = get_discharge_shp(stations)
#' percentiles = calc_discharge_anomalies(discharge)
#' }
calc_discharge_anomalies <- function(discharge) {
  discharge |>
    dplyr::mutate(
      today = furrr::future_map_dbl(data, calc_range_ntile, n_days=1),
      `7` = furrr::future_map_dbl(data, calc_range_ntile, n_days=7),
      `14` = furrr::future_map_dbl(data, calc_range_ntile, n_days=14),
      `28` = furrr::future_map_dbl(data, calc_range_ntile, n_days=28),
    ) |>
    dplyr::select(-data) |>
    tidyr::pivot_longer(
      c("today", "7", "14", "28"),
      names_to = "time"
    ) |>
    dplyr::mutate(fillColor=pal(value))
}
