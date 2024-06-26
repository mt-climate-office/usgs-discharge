% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_discharge.R
\name{get_discharge_shp}
\alias{get_discharge_shp}
\title{Get 30-year discharge data for all gauges returned from \code{\link[=get_gauges]{get_gauges()}}. This
is just a wrapper around \code{\link[=get_discharge]{get_discharge()}} using \code{\link[furrr:future_map2]{furrr::future_pmap()}}. By default,
\code{furrr} uses a sequential plan to get discharge, but you can specify a multisession
plan by running \code{future::plan(future::multisession, workers = 5)} before running the code.}
\usage{
get_discharge_shp(stations)
}
\arguments{
\item{stations}{The \code{sf} object of USGS gauges to get data for.}
}
\value{
An \code{sf} object with a listed dataframe column called \code{data}, where each row's value has daily discharge values for the last 30 years.
}
\description{
Get 30-year discharge data for all gauges returned from \code{\link[=get_gauges]{get_gauges()}}. This
is just a wrapper around \code{\link[=get_discharge]{get_discharge()}} using \code{\link[furrr:future_map2]{furrr::future_pmap()}}. By default,
\code{furrr} uses a sequential plan to get discharge, but you can specify a multisession
plan by running \code{future::plan(future::multisession, workers = 5)} before running the code.
}
\examples{
\dontrun{
stations = get_gauges()
discharge = get_discharge_shp(stations)
}
}
