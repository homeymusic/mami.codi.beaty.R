#' Major-Minor Consonance-Dissonance
#'
#' A model of consonance perception based on the fundamental cycles of complex space and time signals.
#'
#' @param x Chord to analyze, which is parsed using
#'   \code{hrep::sparse_fr_spectrum}. For more details, see
#'   \href{https://github.com/pmcharrison/hrep/blob/master/R/sparse-fr-spectrum.R}{hrep::sparse_fr_spectrum documentation}.
#' @param space_uncertainty Optional space uncertainty value for finding rational fractions.
#' @param time_uncertainty Optional time uncertainty value for finding rational fractions.
#' @param integer_harmonics_tolerance Optional tolerance for harmonics to deviate from perfect integers.
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
#' @rdname mami.codi
#' @export
mami.codi <- function(
    x,
    space_uncertainty                = UNCERTAINTY_LIMIT,
    time_uncertainty                 = UNCERTAINTY_LIMIT,
    integer_harmonics_tolerance      = INTEGER_HARMONICS_TOLERANCE,
    metadata                         = NA,
    verbose                          = FALSE,
    ...
) {

  x %>%
    # R Data Marshaling Domain
    parse_input(...) %>%
    # Physical Domain
    generate_stimulus() %>%
    generate_sidebands() %>%
    # Frequency Domain
    compute_space_cycles(
      space_uncertainty,
      integer_harmonics_tolerance
    ) %>%
    compute_time_cycles(
      time_uncertainty,
      integer_harmonics_tolerance
    ) %>%
    # Psychophysical Domain
    compute_energy_per_cycle()   %>%
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

#' Generate sidebands (pure‐wavelength)
#'
#' For a given stimulus spectrum, compute the spatial beat‐wavelengths
#' for every unordered pair of input wavelengths:
#'   λ_beat = λ_i * λ_j / |λ_j - λ_i|
#' and filter them into range.
#'
#' @param x A list/tibble containing `stimulus_wavelength_spectrum`
#'   (a tibble with `wavelength` and `amplitude`).
#' @return The input `x` augmented with:
#'   - `sidebands_wavelength_spectrum`: filtered sideband wavelengths & amplitudes
#' @export
generate_sidebands <- function(x) {
  wav_spec <- x$stimulus_wavelength_spectrum[[1]]

  sidebands_wavelength_spectrum <- compute_sidebands_wavelength(
    wavelength = wav_spec$wavelength,
    amplitude  = wav_spec$amplitude
  ) %>%
    filter_spectrum_in_range()

  x %>%
    dplyr::mutate(
      sidebands_wavelength_spectrum = list(sidebands_wavelength_spectrum)
    )
}

#' Compute the spatial cycle length of the complex waveform.
#'
#' Computes the spatial cycle length from a wavelength spectrum that
#' includes stimulus, side bands.
#'
#' @param x Wavelength spectrum that include stimulus, side bands.
#' @param space_uncertainty Uncertainty factor applied when creating rational approximations for spatial wavelength.
#' @param integer_harmonics_tolerance Allowable deviation for harmonics that are not perfect integers.
#'
#' @return spatial cycle length
#'
#' @rdname compute_space_cycles
#' @export
compute_space_cycles <- function(
    x,
    space_uncertainty,
    integer_harmonics_tolerance
) {

  wavelength_spectrum = combine_spectra(
    x$stimulus_wavelength_spectrum[[1]],
    x$sidebands_wavelength_spectrum[[1]]
  )

  l = wavelength_spectrum$wavelength

  x %>% dplyr::mutate(

    compute_cycle_length(
      l/min(l),
      DIMENSION$SPACE,
      space_uncertainty,
      integer_harmonics_tolerance
    ),

    # Store the values
    wavelength_spectrum    = list(wavelength_spectrum),
    wavelengths            = list(l),
    space_uncertainty,
    integer_harmonics_tolerance
  )

}

#' Compute the temporal cycle length of a complex waveform.
#'
#' Computes the temporal cycle length from a frequency spectrum that
#' includes stimulus and side bands.
#'
#' @param x Wavelength spectrum that include stimulus and side bands.
#' @param time_uncertainty Uncertainty factor applied when creating rational approximations for temporal frequency.
#' @param integer_harmonics_tolerance Allowable deviation for harmonics that are not perfect integers.
#'
#' @return temporal cycle length
#'
#' @rdname compute_time_cycles
#' @export
compute_time_cycles <- function(
    x,
    time_uncertainty,
    integer_harmonics_tolerance
) {

  frequency_spectrum = combine_spectra(
    x$stimulus_frequency_spectrum[[1]]
  )
  f = frequency_spectrum$frequency

  x %>% dplyr::mutate(

    compute_cycle_length(
      f/min(f),
      DIMENSION$TIME,
      time_uncertainty,
      integer_harmonics_tolerance
    ),

    # Store the values
    frequency_spectrum     = list(frequency_spectrum),
    frequencies            = list(f),
    time_uncertainty

  )

}

#' Compute the cycle length of a complex wave
#'
#' @param x Spectrum representing a complex waveform
#' @param dimension Space or time, used to label the output
#' @param uncertainty Precision for creating rational approximations
#' @param integer_harmonics_tolerance Allowable toleance for approximating least common multiples (LCM).
#'
#' @return Estimated cycle length of the complex waveform.
#'
#' @rdname compute_cycle_length
#' @export
compute_cycle_length <- function(x, dimension, uncertainty, integer_harmonics_tolerance) {

  fractions = approximate_rational_fractions(x, uncertainty, integer_harmonics_tolerance)

  t = tibble::tibble_row(
    cycle_length = lcm_integers(fractions$den),
    euclids_orchard_height = sum(fractions$euclids_orchard_height),
    thomae = sum(fractions$thomae),
    depth = sum(fractions$depth),
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

    time_dissonance  = log2(.data$time_cycle_length),
    space_dissonance = log2(.data$space_cycle_length),

    dissonance = log2(.data$time_cycle_length * .data$space_cycle_length),
    majorness  = log2(.data$space_cycle_length / .data$time_cycle_length),

    stern_brocot_time_depth  = log2(.data$time_depth),
    stern_brocot_space_depth = log2(.data$space_depth),

    stern_brocot_depth      = log2(.data$space_depth * .data$time_depth),
    stern_brocot_depth_diff = log2(.data$space_depth / .data$time_depth)

  )

}

#' Compute energy density per cycle
#'
#' Calculates energy density per cycle.
#'
#' @param x The spectrum of stimulus and side bands.
#'
#' @return Physics measure of energy per cycle.
#'
#' @rdname compute_energy_per_cycle
#' @export
compute_energy_per_cycle <- function(x) {

  energy_per_cycle = energy_per_cycle(x$wavelength_spectrum[[1]])

  x %>% dplyr::mutate(
    energy_per_cycle
  )

}

energy_per_cycle <- function(
    x
) {
  if (nrow(x) > 0) {
    log2(1+sum(x$amplitude ^ 2 * x$wavelength, na.rm = TRUE))
  } else {
    0
  }
}

# Constants

#' Uncertainty limit
#'
#' Uncertainty limit for the uncertainty products of
#' time, frequency or space, wavelength
#'
#'
#' @rdname uncertainty_limit
#' @export
uncertainty_limit <- function() { UNCERTAINTY_LIMIT }
UNCERTAINTY_LIMIT = 1 / (4 * pi)

#' Default integer harmonic tolerance
#'
#' Tolerance for the case when harmonics are not perfect integers
#' useful for approximating the Least Common Multiple (LCM) and
#' to determine the pseudo octave in the case of stretched timbre
#'
#''
#' @rdname default_integer_harmonics_tolerance
#' @export
default_integer_harmonics_tolerance <- function() { INTEGER_HARMONICS_TOLERANCE }
INTEGER_HARMONICS_TOLERANCE = 0.11

#' Speed of Sound
#'
#' Default minimum amplitude for deciding which tones are evaluated
#'
#''
#' @rdname speed_of_sound
#' @export
speed_of_sound <- function() { C_SOUND }
C_SOUND = 343 # m/s arbitrary, disappears in the ratios

DIMENSION <- list(
  SPACE = 'space',
  TIME  = 'time'
)

MAX_FREQUENCY = hrep::midi_to_freq(127 + 24)
MIN_FREQUENCY = 1

MAX_WAVELENGTH = C_SOUND / MIN_FREQUENCY
MIN_WAVELENGTH = C_SOUND / MAX_FREQUENCY
