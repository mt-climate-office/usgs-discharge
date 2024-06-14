roi <- sf::read_sf(
  "https://raw.githubusercontent.com/mt-climate-office/usgs-discharge/master/data-raw/umrb_domain.geojson"
)

API_URL = "https://wcc.sc.egov.usda.gov/awdbRestApi/services/v1"
# docs: https://wcc.sc.egov.usda.gov/awdbRestApi/swagger-ui/index.html

get_station_list <- function(roi, filter_start) {

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
      dplyr::filter(begin_date <= filter_start)

    return(stations)
  } else {
    stop(glue::glue("Unable to hit {response$url}"))
  }
}

parse_data_json <- function(x) {
  meta <- tibble::as_tibble(x$stationElement) |>
    janitor::clean_names() |>
    dplyr::select(
      element_code,
      height_depth,
      stored_unit_code
    )

  purrr::map(x$values, tibble::as_tibble) |>
    dplyr::bind_rows() |>
    dplyr::cross_join(meta)
}

get_station_data <- function(station_triplet, start_date, ...) {

  response <- httr::GET(
    url = file.path(API_URL, "data"),
    query = list(
      stationTriplets = station_triplet,
      elements = "SMS:*",
      duration = "DAILY",
      beginDate = start_date,
      endDate = "2100-01-01",
      returnFlags = TRUE
    )
  )

  if (httr::status_code(response) == 200) {
    content = httr::content(response) |>
      purrr::map(\(station) {
        dat <- purrr::map(station$data, parse_data_json) |>
          dplyr::bind_rows() |>
          dplyr::mutate(
            station = station$stationTriplet,
            date = as.Date(date),
            depth = factor(height_depth)
          ) |>
          dplyr::filter(value > 0, value < 100)
      })
  } else {
    stop(glue::glue("Unable to hit {response$url}"))
  }
}

filter_start =
  lubridate::today() - lubridate::years(30) - lubridate::days(30)

stations <- get_stations(roi = roi,start_date = filter_start, type="sm")
future::plan(future::multisession, workers = future::availableCores() -1)
dat <- furrr::future_pmap(
  stations, get_station_data, start_date = filter_start
)
