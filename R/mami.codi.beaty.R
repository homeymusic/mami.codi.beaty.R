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
    generate_superposition_envelope() %>%
    # Frequency Domain
    compute_space_cycles() %>%
    compute_time_cycles() %>%
    compute_energy_per_cycle() %>%
    # Psychophysical Domain
    compute_harmony_perception() %>%
    # App Domain
    format_output(metadata, verbose)

}

#' Generate the stimulus tones as frequency and wavelength spectra
#'
#' @param x A sparse frequency spectrum from \code{hrep}, representing the
#' frequency content of the stimulus tones.
#'
#' @return The frequency and wavelength spectra for the stimulus tones.
#'
#' @rdname generate_stimulus
#' @export
generate_stimulus <- function(
    x
) {

  stimulus_frequency_spectrum  = frequency_spectrum_from_sparse_fr_spectrum(x)

  stimulus_wavelength_spectrum = wavelength_spectrum_from_sparse_fr_spectrum(x)

  # Store the values
  tibble::tibble_row(
    stimulus_frequency_spectrum  = list(stimulus_frequency_spectrum),
    stimulus_wavelength_spectrum = list(stimulus_wavelength_spectrum),
    source_spectrum              = list(x)
  )

}

#' Generate amplitude modulation
#'
#' For a given stimulus spectrum, compute the difference frequncies
#' and the spectral sidebands (fi ± |fj – fi|) for every unordered
#' pair of input frequencies, then convert to wavelength and filter into range.
#'
#' @param x A list or tibble containing `stimulus_frequency_spectrum`
#'   (a data.frame/tibble with `frequency` and `amplitude` columns).
#' @return The input `x` augmented with:
#'   - `amplitude_modulation_frequency_spectrum`: filtered sideband frequencies & amplitudes
#'   - `amplitude_modulation_wavelength_spectrum`: corresponding wavelengths & amplitudes
#' @rdname generate_sidebands
#' @export
generate_superposition_envelope <- function(x) {

  sideband_frequency_spectrum <- compute_amplitude_modulation(
    frequency = x$stimulus_frequency_spectrum[[1]]$frequency,
    amplitude  = x$stimulus_frequency_spectrum[[1]]$amplitude
  ) %>% filter_spectrum_in_range()

  sideband_wavelength_spectrum <- tibble::tibble(
    wavelength = SPEED_OF_SOUND / sideband_frequency_spectrum$frequency,
    amplitude  = sideband_frequency_spectrum$amplitude
  ) %>%
    filter_spectrum_in_range()

  x %>%
    dplyr::mutate(
      sideband_frequency_spectrum = list(sideband_frequency_spectrum),
      sideband_wavelength_spectrum = list(sideband_wavelength_spectrum)
    )
}

#' Compute the spatial cycle length of the complex waveform.
#'
#' Computes the spatial cycle length from a wavelength spectrum that
#' includes stimulus, side bands.
#'
#' @param x Wavelength spectrum that include stimulus, side bands.
#'
#' @return spatial cycle length
#'
#' @rdname compute_space_cycles
#' @export
compute_space_cycles <- function(
    x
) {

  l_min <- min(x$stimulus_wavelength_spectrum[[1]]$wavelength)

  wavelength_spectrum = validate_combine_spectra(
    x$stimulus_wavelength_spectrum[[1]],
    x$sideband_wavelength_spectrum[[1]]
  ) %>% filter_spectrum_in_range(wavelength_min = l_min)

  l = wavelength_spectrum$wavelength

  x %>% dplyr::mutate(

    compute_cycle_length(
      l,
      l_min,
      DIMENSION$SPACE
    ),

    # Store the values
    wavelength_spectrum    = list(wavelength_spectrum),
    wavelengths            = list(l)
  )

}

#' Compute the temporal cycle length of a complex waveform.
#'
#' Computes the temporal cycle length from a frequency spectrum that
#' includes stimulus and side bands.
#'
#' @param x Wavelength spectrum that include stimulus and side bands.
#'
#' @return temporal cycle length
#'
#' @rdname compute_time_cycles
#' @export
compute_time_cycles <- function(
    x
) {

  f_min <- min(x$stimulus_frequency_spectrum[[1]]$frequency)

  frequency_spectrum = validate_combine_spectra(
    x$stimulus_frequency_spectrum[[1]],
    x$sideband_frequency_spectrum[[1]]
  ) %>% filter_spectrum_in_range(frequency_min = f_min)

  f     <- frequency_spectrum$frequency

  x %>% dplyr::mutate(

    compute_cycle_length(
      f,
      f_min,
      DIMENSION$TIME
    ),

    # Store the values
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
#' of dissonance perception. The sum of wavelength dissonance and frequency
#' dissonance provides an overall sense of dissonance, while the difference
#' indicates major-minor tonality.
#'
#' @param x Cycle lengths for the fundamental frequency and fundamental wavelength.
#'
#' @return Overall dissonance and major-minor tonality perception.
#'
#' @rdname compute_harmony_perception
#' @export
compute_harmony_perception <- function(x) {

  x %>% dplyr::mutate(

    space_periodicity = log2(.data$space_cycle_length),  # spatial extent
    time_periodicity  = log2(.data$time_cycle_length),   # temporal extent

    space_roughness   = log2(.data$space_depth), # spatial  energy density
    time_roughness    = log2(.data$time_depth),  # temporal energy density

    space_dissonance  = .data$space_periodicity + .data$space_roughness, # spatial  energy
    time_dissonance   = .data$time_periodicity  + .data$time_roughness,  # temporal energy

    dissonance        = .data$space_dissonance + .data$time_dissonance,
    majorness         = .data$space_dissonance - .data$time_dissonance

  )

}

#' Compute energy per cycle
#'
#' Calculates energy per cycle.
#'
#' @param x The spectrum of stimulus and side bands.
#'
#' @return Physics measure of energy per cycle.
#'
#' @rdname compute_energy_per_cycle
#' @export
compute_energy_per_cycle <- function(x) {

  x %>% dplyr::mutate(
    energy_per_cycle = energy_per_cycle(x$wavelength_spectrum[[1]])
  )

}

#' this is a made up metric that felt right to me
#' over one spatial cycle we are spatially
#' displacing material by amplitude A.
#'
#' if we were to multiply it by bulk modulus
#' we would have units of energy
#'
#' https://en.wikipedia.org/wiki/Bulk_modulus
#'
energy_per_cycle <- function(
    x
) {
  if (nrow(x) > 0) {
    sum( x$amplitude^2 * x$wavelength, na.rm = TRUE)
  } else {
    0
  }
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

SPEED_OF_SOUND = hrep::midi_to_freq(65)

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

GOLDEN_RATIO     <- (1+sqrt(5)) / 2
OCTAVE_RATIO     <- 2
