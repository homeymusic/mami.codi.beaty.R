run_trials <- function(search_label, standard_deviations, heisenberg) {
  devtools::load_all(".")
  tonic_midi = 60
  source('./utils.R')

  library(mami.codi.R)

  num_harmonics = 10
  pseudo_octave  = 2.0
  roll_off      = 3

  if (search_label == 'Stretched') {
    pseudo_octave  = 2.1
  } else if (search_label == 'Compressed') {
    pseudo_octave  = 1.9
  } else if (search_label == 'Pure') {
    num_harmonics = 1
  } else if (search_label == '5Partials') {
    num_harmonics = 5
  }

  print(search_label)
  print(paste('pseudo_octave:',pseudo_octave))
  print(paste('num_harmonics:',num_harmonics))
  print(paste('roll_off:',roll_off))

  rds = paste0('../data/standard_deviation_',
               search_label,
               '.rds')
  prepare(rds)

  behavior.rds = paste0('../data/',
                        search_label,
                        '.rds')
  behavior = readRDS(behavior.rds)

  interval = tonic_midi + behavior$profile$interval

  grid = tidyr::expand_grid(
    interval,
    standard_deviation = standard_deviations
  )

  print(grid)

  plan(multisession, workers=parallelly::availableCores())

  data = grid %>% furrr::future_pmap_dfr(\(
    interval,
    standard_deviation
  ) {

    if (search_label=='Bonang') {
      bass_f0 <- hrep::midi_to_freq(tonic_midi)
      bass_df <- tibble::tibble(
        frequency = bass_f0 * 1:4,
        amplitude = 1
      )
      upper_f0 <- hrep::midi_to_freq(interval)
      chord_df <- tibble::tibble(
        frequency = c(upper_f0 * c(1, 1.52, 3.46, 3.92),
                      bass_df$frequency) %>% unique %>% sort,
        amplitude = 1
      )
      chord = chord_df %>% as.list() %>% hrep::sparse_fr_spectrum()
    } else if (search_label == '5PartialsNo3') {
      bass_f0 <- hrep::midi_to_freq(tonic_midi)
      bass <- tibble::tibble(
        frequency = bass_f0 * 1:5,
        amplitude = c(1, 1, 0, 1, 1)
      ) %>% as.list() %>%  hrep::sparse_fr_spectrum()

      upper_f0 <- hrep::midi_to_freq(interval)
      upper <- tibble::tibble(
        frequency = upper_f0 * 1:5,
        amplitude = c(1, 1, 0, 1, 1)
      ) %>% as.list() %>%  hrep::sparse_fr_spectrum()

      chord = do.call(hrep::combine_sparse_spectra, list(bass,upper))
    } else {
      chord = hrep::sparse_fr_spectrum(c(tonic_midi, interval),
                                       num_harmonics = num_harmonics,
                                       roll_off_dB   = roll_off,
                                       pseudo_octave  = pseudo_octave
      )
    }

    mami.codi.R::mami.codi(
      chord,
      temporal_standard_deviation  = standard_deviation,
      spatial_standard_deviation   = mami.codi.R::default_standard_deviation(),
      metadata       = list(
        pseudo_octave   = pseudo_octave,
        num_harmonics  = num_harmonics,
        roll_off_dB    = roll_off,
        semitone       = interval - tonic_midi
      ),
      verbose=T
    )
  }, .progress=TRUE, .options = furrr::furrr_options(seed = T))

  saveRDS(data,rds)
}
