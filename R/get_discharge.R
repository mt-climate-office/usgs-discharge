#' Get the last 30 years of discharge data from a given USGS Gauge.
#'
#' @param STAID The 8-digit USGS station code to get data for.
#'
#' @return A `tibble` with "date" and "val" columns, where "val" is the discharge in cfs.
#' @export
#'
#' @examples
#' get_discharge("05014500")
get_discharge <- function(STAID) {
  end <- (Sys.time() |>
            lubridate::as_date()) - 1

  month <- lubridate::month(end)
  day <- lubridate::day(end)

  start <- end - lubridate::years(31)

  dat <- suppressWarnings(waterData::importDVs(
    STAID, code="00060", sdate = start, edate = end
  ))

  if (nrow(dat) == 0) {
    return(NA)
  }

  dat |>
    dplyr::select(date=dates, val) |>
    tibble::tibble()
}



#' Get 30-year discharge data for all gauges returned from [get_gauges()]. This
#' is just a wrapper around [get_discharge()] using [furrr::future_pmap()]. By default,
#' `furrr` uses a sequential plan to get discharge, but you can specify a multisession
#' plan by running `future::plan(future::multisession, workers = 5)` before running the code.
#'
#' @param stations The `sf` object of USGS gauges to get data for.
#'
#' @return An `sf` object with a listed dataframe column called `data`, where each row's value has daily discharge values for the last 30 years.
#' @export
#'
#' @examples
#' \dontrun{
#' stations = get_gauges()
#' discharge = get_discharge_shp(stations)
#' }
get_discharge_shp <- function(stations) {

  stations |>
    dplyr::mutate(data = furrr::future_pmap(list(STAID), get_discharge), seed=NULL) |>
    dplyr::filter(!is.na(data)) |>
    dplyr::filter(purrr::map_lgl(data, ~ nrow(.x) > 11000))
}


