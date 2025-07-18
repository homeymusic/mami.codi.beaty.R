tonic_midi = 60

local_result = devtools::install('/Users/homeymusic/Documents/git/homeymusic/mami.codi.beaty.R')

if (is.na(local_result)) {
  stop("Fatal error: Unable to install the package. Please check the repository and branch name.")
} else {
  message("Repo looks good: ", local_result)
}

source('./man/code/utils.R')

library(mami.codi.beaty.R)
devtools::load_all(".")

output.rds = './man/data/output/readme.rds'
prepare(output.rds)

experiment.rds = './man/data/input/Pure.rds'
grid_1 = tidyr::expand_grid(
  interval = readRDS(experiment.rds)$profile$interval,
  num_harmonics=1,
  pseudo_octave=2.0,
  timbre = 'Pure'
)

experiment.rds = './man/data/input/Bonang.rds'
grid_Bonang = tidyr::expand_grid(
  interval = readRDS(experiment.rds)$profile$interval,
  num_harmonics=4,
  pseudo_octave=2,
  timbre = 'Bonang'
)

experiment.rds = './man/data/input/5Partials.rds'
grid_5 = tidyr::expand_grid(
  interval = readRDS(experiment.rds)$profile$interval,
  num_harmonics=5,
  pseudo_octave=2.0,
  timbre='5Partials'
)

experiment.rds = './man/data/input/5PartialsNo3.rds'
grid_5PartialsNo3 = tidyr::expand_grid(
  interval = readRDS(experiment.rds)$profile$interval,
  num_harmonics=5,
  pseudo_octave=2.0,
  timbre = '5PartialsNo3'
)

experiment.rds = './man/data/input/Harmonic.rds'
grid_10 = tidyr::expand_grid(
  interval = readRDS(experiment.rds)$profile$interval,
  num_harmonics=10,
  pseudo_octave=2.0,
  timbre='Harmonic'
)

experiment.rds = './man/data/input/Stretched.rds'
grid_10_stretched = tidyr::expand_grid(
  interval = readRDS(experiment.rds)$profile$interval,
  num_harmonics = 10,
  pseudo_octave = 2.1,
  timbre = 'Stretched'
)

experiment.rds = './man/data/input/Compressed.rds'
grid_10_compressed = tidyr::expand_grid(
  interval = readRDS(experiment.rds)$profile$interval,
  num_harmonics=10,
  pseudo_octave=1.9,
  timbre = 'Compressed'
)

experiment.rds = './man/data/input/M3.rds'
grid_M3 = tidyr::expand_grid(
  interval = readRDS(experiment.rds)$profile$interval,
  num_harmonics=10,
  pseudo_octave=2.0,
  timbre = 'M3'
)

experiment.rds = './man/data/input/M6.rds'
grid_M6 = tidyr::expand_grid(
  interval = readRDS(experiment.rds)$profile$interval,
  num_harmonics=10,
  pseudo_octave=2.0,
  timbre = 'M6'
)

experiment.rds = './man/data/input/P8.rds'
grid_P8 = tidyr::expand_grid(
  interval = readRDS(experiment.rds)$profile$interval,
  num_harmonics=10,
  pseudo_octave=2.0,
  timbre = 'P8'
)

# Predictions

grid_m3 = tidyr::expand_grid(
  interval = seq(from = 2.85, to = 3.35, length.out = 1000),
  num_harmonics=10,
  pseudo_octave=2.0,
  timbre = 'm3'
)

grid_m6 = tidyr::expand_grid(
  interval = seq(from = 7.85, to = 8.35, length.out = 1000),
  num_harmonics=10,
  pseudo_octave=2.0,
  timbre = 'm6'
)

grid_P1 = tidyr::expand_grid(
  interval = seq(from = -0.25, to = 0.25, length.out = 1000),
  num_harmonics=10,
  pseudo_octave=2.0,
  timbre = 'P1'
)

# Thus, 2.2 is stretched a bit too far, and ...
experiment.rds = './man/data/input/Stretched.rds'
grid_10_extra_stretched = tidyr::expand_grid(
  interval = readRDS(experiment.rds)$profile$interval,
  num_harmonics = 10,
  pseudo_octave = 2.2,
  timbre = 'ExtraStretched'
)

# ... 1.87 is squished a bit too much. (Sethares p.110 Chapter 6 Plastic City: A Stretched Journey)
experiment.rds = './man/data/input/Compressed.rds'
grid_10_extra_compressed = tidyr::expand_grid(
  interval = readRDS(experiment.rds)$profile$interval,
  num_harmonics=10,
  pseudo_octave=1.87,
  timbre = 'ExtraCompressed'
)

grid_2PartialsFramed = tidyr::expand_grid(
  interval = seq(from = 0.0, to = 15.0, length.out = 1000),
  num_harmonics=2,
  pseudo_octave=2.0,
  timbre = '2PartialsFramed'
)


grid = dplyr::bind_rows(
  grid_1,
  grid_Bonang,
  grid_5,grid_5PartialsNo3,
  grid_10,
  grid_10_stretched,grid_10_compressed,
  grid_M3,grid_M6,grid_P8,
  grid_m3,grid_m6,grid_P1,
  grid_10_extra_stretched,grid_10_extra_compressed,
  grid_2PartialsFramed
)

plan(multisession, workers=parallelly::availableCores())

output = grid %>% furrr::future_pmap_dfr(\(interval,
                                           num_harmonics,
                                           pseudo_octave,
                                           timbre) {

  if (timbre == 'Bonang') {
    bass_f0 <- hrep::midi_to_freq(tonic_midi)
    bass <- tibble::tibble(
      frequency = bass_f0 * 1:4,
      amplitude = 1
    ) %>% as.list() %>%  hrep::sparse_fr_spectrum()

    upper_f0 <- hrep::midi_to_freq(interval + tonic_midi)
    upper <- tibble::tibble(
      frequency = upper_f0 * (c(1, 1.52, 3.46, 3.92)),
      amplitude = 1
    ) %>% as.list() %>%  hrep::sparse_fr_spectrum()

    study_chord = do.call(hrep::combine_sparse_spectra, list(bass,upper))
  } else if (timbre == '5PartialsNo3') {
    bass_f0 <- hrep::midi_to_freq(tonic_midi)
    bass <- tibble::tibble(
      frequency = bass_f0 * 1:5,
      amplitude = c(1, 1, 0, 1, 1)
    ) %>% as.list() %>%  hrep::sparse_fr_spectrum()

    upper_f0 <- hrep::midi_to_freq(interval + tonic_midi)
    upper <- tibble::tibble(
      frequency = upper_f0 * 1:5,
      amplitude = c(1, 1, 0, 1, 1)
    ) %>% as.list() %>%  hrep::sparse_fr_spectrum()

    study_chord = do.call(hrep::combine_sparse_spectra, list(bass,upper))
  } else if (timbre == '2PartialsFramed') {
    study_chord = c(tonic_midi, interval + tonic_midi, tonic_midi + 12.0) %>% hrep::sparse_fr_spectrum(
      num_harmonics = num_harmonics,
      pseudo_octave  = pseudo_octave,
      roll_off_dB   = 3.0
    )
  } else {
    study_chord = c(tonic_midi, interval + tonic_midi) %>% hrep::sparse_fr_spectrum(
      num_harmonics = num_harmonics,
      pseudo_octave  = pseudo_octave,
      roll_off_dB   = 3.0
    )
  }

  mami.codi.beaty.R::mami.codi.beaty(study_chord,
                         num_harmonics       = num_harmonics,
                         pseudo_octave        = pseudo_octave,
                         metadata = list(
                           num_harmonics       = num_harmonics,
                           pseudo_octave        = pseudo_octave,
                           semitone            = interval,
                           timbre              = timbre
                         ),
                         verbose=TRUE)

}, .progress=TRUE, .options = furrr::furrr_options(seed = T))
saveRDS(output,output.rds)
