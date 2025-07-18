#' Major-Minor Consonance-Dissonance Beating
#'
#' A model of consonance perception based on the fundamental cycles of complex space and time signals.
#'
#' @param x Chord to analyze, which is parsed using
#'   \code{hrep::sparse_fr_spectrum}. For more details, see
#'   \href{https://github.com/pmcharrison/hrep/blob/master/R/sparse-fr-spectrum.R}{hrep::sparse_fr_spectrum documentation}.
#' @param metadata User-provided list of metadata that accompanies each call. Useful for analysis and plots.
#' @param verbose Determines the amount of data to return from chord evaluation. Options are:
#'   \describe{
#'     \item{\code{TRUE}}{Returns all available evaluation data.}
#'     \item{\code{FALSE}}{Returns only essential data: major/minor classification, consonance/dissonance, and metadata.}
#'   }
#' @param ... Additional parameters for \code{hrep::sparse_fr_spectrum}.
#'
#' @return Major-Minor (majorness), Consonance-Dissonance (dissonance), and metadata, with additional
#'   information if \code{verbose = TRUE}.
#'
#' @rdname mami.codi.beaty
#' @export
mami.codi.beaty <- function(
    x,
    metadata = NA,
    verbose  = FALSE,
    ...
) {

  x %>%
    # R Data Marshaling Domain
    parse_input(...) %>%
    # Physical Domain
    generate_stimulus() %>%
    generate_cubic_distortion_products() %>%
    # Frequency Domain
    compute_space_cycles() %>%
    compute_time_cycles() %>%
    # Psychophysical Domain
    compute_harmony_perception() %>%
    # App Domain
    format_output(metadata, verbose)

}

#' Generate the stimulus tones as frequency and wavenumber spectra
#'
#' @param x A sparse frequency spectrum from \code{hrep}, representing the
#' frequency content of the stimulus tones.
#'
#' @return The frequency and wavenumber spectra for the stimulus tones.
#'
#' @rdname generate_stimulus
#' @export
generate_stimulus <- function(
    x
) {

  stimulus_frequency_spectrum  = frequency_spectrum_from_sparse_fr_spectrum(x)

  stimulus_wavenumber_spectrum = wavenumber_spectrum_from_sparse_fr_spectrum(x)

  # Store the values
  tibble::tibble_row(
    stimulus_frequency_spectrum  = list(stimulus_frequency_spectrum),
    stimulus_wavenumber_spectrum = list(stimulus_wavenumber_spectrum),
    source_spectrum              = list(x)
  )

}

#' Generate generate_cubic_distortion_products
#'
#' For a given stimulus spectrum, compute the difference frequncies
#' and the spectral sidebands (fi ± |fj – fi|) for every unordered
#' pair of input frequencies, then convert to wavenumber and filter into range.
#'
#' @param x A list or tibble containing `stimulus_frequency_spectrum`
#'   (a data.frame/tibble with `frequency` and `amplitude` columns).
#' @return The input `x` augmented with:
#'   - `cubic_distortion_frequency_spectrum`: filtered sideband frequencies & amplitudes
#'   - `cubic_distortion_wavenumber_spectrum`: corresponding wavenumbers & amplitudes
#' @rdname generate_cubic_distortion_products
#' @export
generate_cubic_distortion_products <- function(x) {

  cubic_distortion_frequency_spectrum <- compute_cubic_distortion_products(
    frequency = x$stimulus_frequency_spectrum[[1]]$frequency,
    amplitude  = x$stimulus_frequency_spectrum[[1]]$amplitude
  ) %>% filter_spectrum_in_range()

  cubic_distortion_wavenumber_spectrum <- tibble::tibble(
    wavenumber = cubic_distortion_frequency_spectrum$frequency / SPEED_OF_SOUND,  # cycles per metre
    amplitude  = cubic_distortion_frequency_spectrum$amplitude
  ) %>%
    filter_spectrum_in_range()

  x %>%
    dplyr::mutate(
      cubic_distortion_frequency_spectrum = list(cubic_distortion_frequency_spectrum),
      cubic_distortion_wavenumber_spectrum = list(cubic_distortion_wavenumber_spectrum)
    )
}
#' Compute the spatial cycle length of the complex waveform.
#'
#' Computes the spatial cycle length from a wavenumber spectrum that
#' includes stimulus, side bands.
#'
#' @param x wavenumber spectrum that include stimulus, side bands.
#'
#' @return spatial cycle length
#'
#' @rdname compute_space_cycles
#' @export
compute_space_cycles <- function(
    x
) {

  wavenumber_spectrum = validate_combine_spectra(
    x$stimulus_wavenumber_spectrum[[1]],
    x$cubic_distortion_wavenumber_spectrum[[1]]
  )

  k_max <- max(x$stimulus_wavenumber_spectrum[[1]]$wavenumber)
  k = wavenumber_spectrum$wavenumber

  x %>% dplyr::mutate(

    compute_cycle_length(
      k,
      k_max,
      DIMENSION$SPACE
    ),

    # Store the values
    fundamental_wavenumber = k_max / .data$space_cycle_length,
    fundamental_wavelength = 1 / .data$fundamental_wavenumber,
    wavenumber_spectrum    = list(wavenumber_spectrum),
    wavenumbers            = list(k)
  )

}

#' Compute the temporal cycle length of a complex waveform.
#'
#' Computes the temporal cycle length from a frequency spectrum that
#' includes stimulus and side bands.
#'
#' @param x wavenumber spectrum that include stimulus and side bands.
#'
#' @return temporal cycle length
#'
#' @rdname compute_time_cycles
#' @export
compute_time_cycles <- function(
    x
) {

  frequency_spectrum = validate_combine_spectra(
    x$stimulus_frequency_spectrum[[1]],
    x$cubic_distortion_frequency_spectrum[[1]]
  )

  f_min <- min(x$stimulus_frequency_spectrum[[1]]$frequency)
  f     <- frequency_spectrum$frequency

  x %>% dplyr::mutate(

    compute_cycle_length(
      f,
      f_min,
      DIMENSION$TIME
    ),

    # Store the values
    fundamental_frequency  = f_min / .data$time_cycle_length,
    fundamental_period     = 1 / .data$fundamental_frequency,
    frequency_spectrum     = list(frequency_spectrum),
    frequencies            = list(f)

  )

}

#' Compute the cycle length of a complex wave
#'
#' @param x Spectrum representing a complex waveform
#' @param dimension Space or time, used to label the output
#'
#' @return Estimated cycle length of the complex waveform.
#'
#' @rdname compute_cycle_length
#' @export
compute_cycle_length <- function(x, ref, dimension) {

  fractions = approximate_rational_fractions(x, ref, uncertainty())

  t = tibble::tibble_row(
    cycle_length = lcm_integers(fractions$den),
    euclids_orchard_height = sum(fractions$euclids_orchard_height),
    thomae = sum(fractions$thomae),
    minkowski = sum(fractions$minkowski),
    entropy = sum(fractions$entropy),
    depth = sum(fractions$depth),
    error_sum = sum(abs(fractions$error)),
    fractions = list(fractions)
  ) %>% dplyr::rename_with(~ paste0(dimension, '_' , .))
  t

}

lcm_integers <- function(x) {
  if (length(x) == 0) {
    return(1)
  }
  Reduce(gmp::lcm.bigz, x) %>%
    as.numeric()
}

#' Compute harmony perception from cycle lengths
#'
#' Computes harmony perception based on cycle lengths from the spatial
#' and temporal frequency domains, converting them into psychophysical measures
#' of dissonance perception. The sum of wavenumber dissonance and frequency
#' dissonance provides an overall sense of dissonance, while the difference
#' indicates major-minor tonality.
#'
#' @param x Cycle lengths for the fundamental frequency and fundamental wavenumber.
#'
#' @return Overall dissonance and major-minor tonality perception.
#'
#' @rdname compute_harmony_perception
#' @export
compute_harmony_perception <- function(x) {

  x %>% dplyr::mutate(

    space_roughness   = log2(1 + .data$space_depth), # spatial  energy density
    time_roughness    = log2(1 + .data$time_depth),  # temporal energy density
    roughness         = .data$space_roughness + .data$time_roughness,

    space_periodicity = log2(.data$space_cycle_length),  # spatial extent
    time_periodicity  = log2(.data$time_cycle_length),   # temporal extent
    periodicity       = .data$space_periodicity + .data$time_periodicity,

    space_dissonance  = .data$space_roughness + .data$space_periodicity, # spatial  energy
    time_dissonance   = .data$time_roughness  + .data$time_periodicity,  # temporal energy

    dissonance        = .data$space_dissonance + .data$time_dissonance,
    majorness         = .data$space_dissonance - .data$time_dissonance

  )

}

# Constants

UNCERTAINTY_LIMIT = 1 / (4 * pi)
NUMBER_OF_OBSERVATION_PERIODS = 1

#' Compute uncertainty
#'
#' Uncertainty is the Heisenberg uncertainty limit divided by number of periods
#'
#'
#' @return Uncertainty
#'
#' @rdname uncertainty
#' @export
uncertainty <- function() {
  UNCERTAINTY_LIMIT / NUMBER_OF_OBSERVATION_PERIODS
}

SPEED_OF_SOUND = 343.0

DIMENSION <- list(
  SPACE = 'space',
  TIME  = 'time'
)

# Phase-locking range
MIN_FREQUENCY    <- 20
MAX_FREQUENCY    <- 4000

# Place-coding (BM) range
MAX_WAVELENGTH   <- SPEED_OF_SOUND / 20
MIN_WAVELENGTH   <- SPEED_OF_SOUND / 20000

MIN_WAVENUMBER <- 1 / MAX_WAVELENGTH    # = 20   / SPEED_OF_SOUND
MAX_WAVENUMBER <- 1 / MIN_WAVELENGTH    # = 20000 / SPEED_OF_SOUND

GOLDEN_RATIO     <- (1+sqrt(5)) / 2
OCTAVE_RATIO     <- 2
