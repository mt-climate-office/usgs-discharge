library(magrittr)

#' Get an `sf` object of active USGS stream gauges.
#'
#' @param clip_shp An optional `sf` object to clip the output to.
#'
#' @return An `sf` object clipped to `clip_shp` of USGS gauges.
#' @export
#'
#' @examples
#' \dontrun{
#' gauges <- get_stations_shp()
#' }
get_gauges <- function(clip_shp=NULL) {
  url <- "https://water.usgs.gov/waterwatch/realstx/realstx_shp.tar.gz"

  tmp <- tempfile()

  utils::download.file(url, tmp)

  utils::untar(tmp, exdir = tempdir())

  shp <- list.files(tempdir(), full.names = TRUE, pattern = ".shp") |>
    sf::read_sf() |>
    dplyr::select("STAID", "STANAME")

  if (!is.null(clip_shp)) {
    clip_shp <- sf::st_transform(clip_shp, sf::st_crs(shp))
    shp <- sf::st_crop(shp, clip_shp)
  }

  return(shp)
}

# url = "https://waterservices.usgs.gov/nwis/site/?format=rdb&stateCd=mt&siteOutput=expanded&siteStatus=all"
# read_rdb <- function(url) {
#
#   readr::read_tsv(
#     url,
#     comment = "#"
#   ) |>
#     dplyr::filter(
#       dplyr::row_number() > 1,
#       agency_cd == "USGS"
#     ) |>
#     dplyr::select(
#       site_no, station_nm, dec_lat_va, dec_long_va, construction_dt, inventory_dt
#     ) |> dplyr::filter(!is.na(inventory_dt))
# }
