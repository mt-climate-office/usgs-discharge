% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot.R
\name{make_climatology_plot}
\alias{make_climatology_plot}
\title{Create a plot of current streamflow conditions, with the climatology of the
last 30 years plotted using the USDM color palette.}
\usage{
make_climatology_plot(data, STANAME, STAID, ...)
}
\arguments{
\item{data}{A \code{tibble} returned by \code{\link[=get_discharge]{get_discharge()}}}

\item{STANAME}{The USGS station name for the station you are plotting}

\item{STAID}{The USGS station ID for the station that is being plotted.}

\item{...}{If \code{out_dir} is specified as an additional argument, the plot
will be saved out to \verb{out_dir/\{STAID\}_discharge.png}}
}
\value{
A \code{ggplot} object of the plot. If \code{out_dir} is specified, the output filename is returned.
}
\description{
Create a plot of current streamflow conditions, with the climatology of the
last 30 years plotted using the USDM color palette.
}
\examples{
discharge <-  get_discharge("06077200")
make_climatology_plot(
  discharge,
  "Swiftcurrent Creek at Many Glacier MT",
  "05014500"
)
}
