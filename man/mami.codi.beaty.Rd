% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mami.codi.beaty.R
\name{mami.codi.beaty}
\alias{mami.codi.beaty}
\title{Major-Minor Consonance-Dissonance Beating}
\usage{
mami.codi.beaty(x, metadata = NA, verbose = FALSE, ...)
}
\arguments{
\item{x}{Chord to analyze, which is parsed using
\code{hrep::sparse_fr_spectrum}. For more details, see
\href{https://github.com/pmcharrison/hrep/blob/master/R/sparse-fr-spectrum.R}{hrep::sparse_fr_spectrum documentation}.}

\item{metadata}{User-provided list of metadata that accompanies each call. Useful for analysis and plots.}

\item{verbose}{Determines the amount of data to return from chord evaluation. Options are:
\describe{
\item{\code{TRUE}}{Returns all available evaluation data.}
\item{\code{FALSE}}{Returns only essential data: major/minor classification, consonance/dissonance, and metadata.}
}}

\item{...}{Additional parameters for \code{hrep::sparse_fr_spectrum}.}
}
\value{
Major-Minor (majorness), Consonance-Dissonance (dissonance), and metadata, with additional
information if \code{verbose = TRUE}.
}
\description{
A model of consonance perception based on the fundamental cycles of complex space and time signals.
}
