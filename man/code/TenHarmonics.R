tonic_midi = 60
experiment.rds = './man/data/input/Harmonic.rds'
grid_10 = tidyr::expand_grid(
  interval = readRDS(experiment.rds)$profile$interval,
  num_harmonics=10,
  octave_ratio=2.0,
  timbre='Harmonic'
)

output = grid_10 %>% purrr::pmap_dfr(\(interval,
                                       num_harmonics,
                                       octave_ratio,
                                       timbre) {

  study_chord = c(tonic_midi, interval + tonic_midi) %>% hrep::sparse_fr_spectrum(
    num_harmonics = num_harmonics,
    octave_ratio  = octave_ratio,
    roll_off_dB   = 3.0
  )

  mami.codi(study_chord,
            num_harmonics       = num_harmonics,
            octave_ratio        = octave_ratio,
            metadata = list(
              num_harmonics       = num_harmonics,
              octave_ratio        = octave_ratio,
              semitone            = interval,
              timbre              = timbre
            ),
            verbose=TRUE)

}, .progress=TRUE)

