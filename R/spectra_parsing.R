#' Parse Input
#'
#' Parses the chord to analyse, coerced to hrep::sparse_fr_spectrum
#'
#'
#' @param x Chord to analyse specified in MIDI, coerced to hrep::sparse_fr_spectrum
#' @param ... parameters for hrep::sparse_fr_spectrum
#'
#' @rdname parse_input
#' @export
parse_input <- function(x, ...) {

  UseMethod('parse_input', x)

}

#' @rdname parse_input
#' @export
parse_input.default <- function(x, ...) {

  parse_input(hrep::sparse_fr_spectrum(x, ...), ...)

}

#' @rdname parse_input
#' @export
parse_input.sparse_fr_spectrum <- function(x, ...) {

  x

}

#' Format Output
#'
#' Allows the user to select which columns from the tibble are returned
#'
#'
#' @param x The output tibble with all the data
#' @param metadata Metadata that the user can include that will roundtrip from input to output
#' @param verbose If true then all the data will be included.
#' @param ... parameters for hrep::sparse_fr_spectrum
#'
#' @rdname format_output
#' @export
format_output <- function(x, metadata, verbose) {
  x <- x %>% tibble::add_column(
    metadata=list(metadata)
  )

  if (verbose) {
    x
  } else {
    x %>%
      dplyr::select('majorness',
                    'dissonance',
                    'metadata')
  }
}

# Parsing and marshaling helper functions

#' Helper function to create an empty spectrum
empty_wavelength_spectrum <- function() {
  tibble::tibble(
    wavelength = numeric(),
    amplitude  = numeric()
  )
}

empty_frequency_spectrum <- function() {
  tibble::tibble(
    frequency = numeric(),
    amplitude = numeric()
  )
}

#' Helper functions to combine spectra
validate_combine_spectra <- function(..., tolerance = 1e-15) {
  # Collect all spectra passed in as a list
  spectra_list <- list(...)

  # Check if the list is empty
  if (length(spectra_list) == 0) {
    stop("Error: At least one spectrum must be provided.")
  }

  # Determine the type of spectra based on the first spectrum
  first_spectrum <- spectra_list[[1]]
  if ("frequency" %in% names(first_spectrum)) {
    dimension <- DIMENSION$TIME
    spec_type <- "frequency"
    sort_order <- "asc"
  } else if ("wavelength" %in% names(first_spectrum)) {
    dimension <- DIMENSION$SPACE
    spec_type <- "wavelength"
    sort_order <- "desc"
  } else {
    stop("Error: Spectra must have either 'frequency' or 'wavelength' as a column.")
  }

  # Ensure all spectra have the same type as the first one
  for (spectrum in spectra_list) {
    if (!(spec_type %in% names(spectrum))) {
      stop("Error: All spectra must have the same type (either all frequency or all wavelength).")
    }
  }

  # Combine all spectra into a single tibble
  combined <- dplyr::bind_rows(spectra_list) %>%
    filter_spectrum_in_range() %>%
    dplyr::rename(value = {{spec_type}})

  # Aggregate amplitudes within tolerance for the combined tibble
  result <- combined %>%
    dplyr::arrange(value) %>%
    dplyr::mutate(
      # Group values that fall within the tolerance range
      group = cumsum(c(TRUE, diff(value) > tolerance))
    ) %>%
    dplyr::group_by(group) %>%
    dplyr::summarize(
      value = mean(value),
      amplitude = sum(amplitude),
      .groups = "drop"
    ) %>%
    dplyr::select(!!spec_type := value, amplitude)

  # Apply sorting based on type
  result <- if (sort_order == "asc") {
    result %>% dplyr::arrange(!!rlang::sym(spec_type))
  } else {
    result %>% dplyr::arrange(dplyr::desc(!!rlang::sym(spec_type)))
  }

  return(result)
}


sparse_fr_spectrum_from_wavelength_spectrum <- function(x) {
  hrep::sparse_fr_spectrum(list(
    frequency = SPEED_OF_SOUND / x$wavelength,
    amplitude = x$amplitude
  ))
}

wavelength_spectrum_from_sparse_fr_spectrum <- function(x) {
  tibble::tibble(
    wavelength = SPEED_OF_SOUND / x$x,
    amplitude  = x$y
  ) %>% filter_spectrum_in_range()
}

frequency_spectrum_from_sparse_fr_spectrum <- function(x) {
  tibble::tibble(
    frequency = x$x,
    amplitude = x$y
  ) %>% filter_spectrum_in_range()
}

filter_spectrum_in_range <- function(spectrum) {

  if ("frequency" %in% colnames(spectrum)) {
    # Filter for frequencies within the audible range
    spectrum <- spectrum %>%
      dplyr::filter(amplitude > 1e-15 & frequency >= MIN_FREQUENCY & frequency <= MAX_FREQUENCY)
  } else if ("wavelength" %in% colnames(spectrum)) {
    # Filter for wavelengths within the audible range
    spectrum <- spectrum %>%
      dplyr::filter(amplitude > 1e-15 & wavelength >= MIN_WAVELENGTH & wavelength <= MAX_WAVELENGTH)
  } else {
    stop("The tibble must contain either 'frequency' or 'wavelength' column.")
  }

  return(spectrum)
}
