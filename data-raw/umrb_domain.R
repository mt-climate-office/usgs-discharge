## code to prepare `DATASET` dataset goes here
domain <- sf::read_sf("./data-raw/umrb_domain.geojson")
usethis::use_data(domain, overwrite = TRUE)
