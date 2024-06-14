# get_usgs_start_date <- function(station_id) {
#   url = glue::glue(
#     "https://waterdata.usgs.gov/nwis/inventory?agency_code=USGS&site_no={station_id}"
#   )
#
#   data <- rvest::read_html(url)
#
#   data |>  rvest::html_element('body') |>
#     rvest::html_node("#main-content")
# }

#' Get an `sf` object of active USGS stream gauges.
#'
#' @param roi An optional `sf` object to clip the output to.
#'
#' @return An `sf` object clipped to `roi` of USGS gauges.
#'
#' @examples
#' \dontrun{
#' gauges <- get_stations_shp()
#' }
get_discharge_stations <- function(roi=NULL, start_date = NULL) {
  url <- "https://water.usgs.gov/waterwatch/realstx/realstx_shp.tar.gz"

  tmp <- tempfile()

  utils::download.file(url, tmp)

  utils::untar(tmp, exdir = tempdir())

  shp <- list.files(tempdir(), full.names = TRUE, pattern = ".shp") |>
    sf::read_sf() |>
    dplyr::select("STAID", "STANAME")

  if (!is.null(roi)) {
    shp <- sf::st_crop(shp, roi)
  }

  if (!is.null(start_date)) {
    end_date <- start_date + lubridate::days(1)

  }

  return(shp)
}


# docs: https://wcc.sc.egov.usda.gov/awdbRestApi/swagger-ui/index.html

get_sm_stations <- function(roi=NULL, start_date=NULL) {
  API_URL = "https://wcc.sc.egov.usda.gov/awdbRestApi/services/v1"

  response <- httr::GET(
    url = file.path(API_URL, "stations"),
    query = list(
      stationTriplets = "*:*:SNTL, *:*:SCAN",
      elements = "SMS:*",
      durations = "DAILY",
      activeOnly = TRUE
    )
  )

  if (httr::status_code(response) == 200) {
    stations <- httr::content(response) |>
      purrr::map(tibble::as_tibble) |>
      dplyr::bind_rows() |>
      sf::st_as_sf(
        coords = c("longitude", "latitude"),
        crs = 4326
      ) |>
      sf::st_crop(roi) |>
      janitor::clean_names() |>
      dplyr::select(
        station_triplet,
        station_id,
        state_code,
        network_code,
        name,
        begin_date,
        end_date
      ) |>
      dplyr::mutate(
        begin_date = lubridate::as_date(begin_date |>
                                          stringr::str_replace(" 00:00", "")
        ),
        end_date = lubridate::as_date(end_date |>
                                        stringr::str_replace(" 00:00", "")
        )
      ) |>
      dplyr::filter(
        end_date >= lubridate::today()
      )

    if (!is.null(start_date)) {
      stations <- stations |>
        dplyr::filter(begin_date <= start_date)
    }

    return(stations)
  } else {
    stop(glue::glue("Unable to hit {response$url}"))
  }
}


#' Get an `sf` object of USGS or SNOTEL+SCAN station locations.
#'
#' @param roi An optional `sf` object polygon domain that the station output can be clipped to.
#' @param type Either "sm" or "discharge" to get an `sf` of either SCAN + SNOTEL or USGS
#' discharge stations, respectively.
#'
#' @return An `sf` point dataset of station locations and names.
#' @export
#'
#' @examples
get_stations <- function(roi=NULL, start_date=NULL, type) {
  type <- match.arg(type, c("sm", "discharge"))
  if (!is.null(roi)) {
    stopifnot("sf" %in% class(roi))
    roi <- roi |>
      sf::st_transform(4326)
  }

  if (type == "sm") {
    return(get_sm_stations(roi = roi, start_date = start_date))
  } else {
    return(get_discharge_stations(roi = roi, start_date = start_date))
  }
}

sm <- get_stations(roi = roi,start_date = lubridate::today() - lubridate::years(30), type="sm")
discharge <- get_stations(roi = roi, start_date = lubridate::today() - lubridate::years(30), type="discharge")




