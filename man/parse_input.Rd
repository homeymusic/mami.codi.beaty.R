% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spectra_parsing.R
\name{parse_input}
\alias{parse_input}
\alias{parse_input.default}
\alias{parse_input.sparse_fr_spectrum}
\title{Parse Input}
\usage{
parse_input(x, ...)

\method{parse_input}{default}(x, ...)

\method{parse_input}{sparse_fr_spectrum}(x, ...)
}
\arguments{
\item{x}{Chord to analyse specified in MIDI, coerced to hrep::sparse_fr_spectrum}

\item{...}{parameters for hrep::sparse_fr_spectrum}
}
\description{
Parses the chord to analyse, coerced to hrep::sparse_fr_spectrum
}
