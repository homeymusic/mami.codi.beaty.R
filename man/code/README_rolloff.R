github_result = devtools::install('/Users/homeymusic/Documents/git/homeymusic/mami.codi.R',
                                  ref='main')

if (is.na(github_result)) {
  stop("Fatal error: Unable to install the package from GitHub. Please check the repository and branch name.")
} else {
  message("Repo looks good: ", github_result)
}

source('./utils.R')
library(mami.codi.R)
devtools::load_all(".")

output.rds = '../data/roll_off_timbre_paper.rds'
prepare(output.rds)

tonic_midi = 60


experiment.csv = paste0('../data/',
                        'roll_off_', 2,
                        '.csv')
intervals = tonic_midi + read.csv(experiment.csv)$interval
macro_index = seq_along(intervals)

num_harmonics = 10
pseudo_octave  = 2.0

roll_off=c(2,7,12)
grid_10 = tidyr::expand_grid(
  index=macro_index,
  num_harmonics,
  pseudo_octave,
  roll_off
)

grid = dplyr::bind_rows(grid_10)

plan(multisession, workers=parallelly::availableCores())

output = grid %>% furrr::future_pmap_dfr(\(index, num_harmonics, pseudo_octave,
                                           roll_off) {

  if (roll_off == 2) {
    amplitude = 0.00
  } else if (roll_off == 7) {
    amplitude = 0.08
  } else if (roll_off == 12) {
    amplitude = 0.013
  }

  mami.codi.R::mami.codi(c(tonic_midi,intervals[index]),
                         amplitude = amplitude,
                         num_harmonics=num_harmonics,
                         pseudo_octave=pseudo_octave,
                         roll_off_dB   = roll_off,
                         metadata = list(
                           num_harmonics = num_harmonics,
                           pseudo_octave  = pseudo_octave,
                           semitone      = intervals[index] - tonic_midi,
                           roll_off_dB   = roll_off
                         ),
                         verbose=TRUE)

}, .progress=TRUE, .options = furrr::furrr_options(seed = T))

saveRDS(output,output.rds)
