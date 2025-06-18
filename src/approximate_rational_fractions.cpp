#include <Rcpp.h>
#include <R_ext/Rdynload.h>
using namespace Rcpp;

 //' compute_pseudo_octave
 //'
 //' Find the highest fundamental freq
 //'
 //' @param fn freq to eval
 //' @param f0 fundamental freq
 //' @param n  harmonic number
 //'
 //' @return Calculated pseudo octave
 //'
 //' @export
 // [[Rcpp::export]]
 const double compute_pseudo_octave(const double fn, const double f0, const int n) {
   if (n==1) {
     return 1.0;
   } else {
     const int r = 1000000;
     return std::round(r * pow(2, log(fn / f0) / log(n))) / r;
   }
 }

 //' approximate_harmonics
 //'
 //' Determine pseudo octave of all frequencies relative to lowest frequency
 //'
 //' @param x Chord frequencies
 //' @param deviation Deviation for estimating least common multiples
 //'
 //' @return A double of the best guess of the pseudo octave
 //'
 //' @export
 // [[Rcpp::export]]
 DataFrame approximate_harmonics(const NumericVector x,
                                 const double deviation) {
   const int x_size   = x.size();
   const double f_max = max(x);
   NumericVector harmonic_number(x_size * x_size * x_size);
   NumericVector evaluation_freq(x_size * x_size * x_size);
   NumericVector reference_freq(x_size * x_size * x_size);
   NumericVector reference_amp(x_size * x_size * x_size);
   NumericVector pseudo_octave(x_size * x_size * x_size);
   NumericVector highest_freq(x_size * x_size * x_size);


   const DataFrame default_pseudo_octave = DataFrame::create(
     _("harmonic_number") = 1,
     _("evaluation_freq") = f_max,
     _("reference_freq")  = f_max,
     _("pseudo_octave")   = 2.0,
     _("highest_freq")    = f_max
   );

   if (x_size <= 2) {
     return default_pseudo_octave;
   }

   int num_matches=0;

   for (int eval_freq_index = 0; eval_freq_index < x_size; ++eval_freq_index) {
     for (int ref_freq_index = 0; ref_freq_index < x_size; ++ref_freq_index) {
       for (int harmonic_num = 2; harmonic_num <= x_size; ++harmonic_num) {
         const double p_octave = compute_pseudo_octave(x[eval_freq_index], x[ref_freq_index], harmonic_num);
         if (2.0 - deviation < p_octave && p_octave < 2.0 + deviation) {
           harmonic_number[num_matches] = harmonic_num;
           evaluation_freq[num_matches] = x[eval_freq_index];
           reference_freq[num_matches]  = x[ref_freq_index];
           highest_freq[num_matches]    = f_max;
           pseudo_octave[num_matches]   = p_octave;
           num_matches++;
         }
       }
     }
   }

   if (num_matches == 0) {
     return default_pseudo_octave;
   } else {
     return DataFrame::create(
       _("harmonic_number") = harmonic_number[Rcpp::Range(0, num_matches-1)],
       _("evaluation_freq") = evaluation_freq[Rcpp::Range(0, num_matches-1)],
       _("reference_freq")  = reference_freq[Rcpp::Range(0, num_matches-1)],
       _("pseudo_octave")   = pseudo_octave[Rcpp::Range(0, num_matches-1)],
       _("highest_freq")    = highest_freq[Rcpp::Range(0, num_matches-1)]
     );
   }
 }

 //' pseudo_octave
 //'
 //' Finds the pseudo octave from approximate harmonics.
 //'
 //' @param approximate_harmonics List of candidate pseudo octaves
 //'
 //' @return A data frame of rational numbers and metadata
 //'
 //' @export
 // [[Rcpp::export]]
 const double pseudo_octave(NumericVector approximate_harmonics) {
   const IntegerVector counts = table(approximate_harmonics);
   IntegerVector idx = seq_along(counts) - 1;
   std::sort(idx.begin(), idx.end(), [&](int i, int j){return counts[i] > counts[j];});
   CharacterVector names_of_count = counts.names();
   names_of_count = names_of_count[idx];
   return std::stod(std::string(names_of_count[0]));
 }

 typedef SEXP (*first_coprime_t)(SEXP,SEXP,SEXP);
 static first_coprime_t cpp_first_coprime = nullptr;

 //' approximate_rational_fractions
 //'
 //' Approximates floating-point numbers to arbitrary uncertainty.
 //'
 //' @param x Vector of floating point numbers to approximate
 //' @param uncertainty Precision for finding rational fractions
 //' @param deviation Deviation for estimating least common multiples
 //'
 //' @return A data frame of rational numbers and metadata
 //'
 //' @export
 // [[Rcpp::export]]
 DataFrame approximate_rational_fractions(NumericVector x,
                                          const double uncertainty,
                                          const double deviation) {
   // 1) dedupe and early-return
   x = unique(x);
   int n = x.size();
   if (n == 0) {
     return DataFrame::create();
   }

   // 2) compute the psycho-acoustic transform
   DataFrame harm = approximate_harmonics(x, deviation);
   double pseudo_octave_double = pseudo_octave(harm["pseudo_octave"]);

   // 3) build the vectors we'll pass to coprimer
   NumericVector pseudo_x(n), uvec(n, uncertainty);
   for (int i = 0; i < n; ++i) {
     pseudo_x[i] = std::pow(2.0,
                            std::log(x[i]) / std::log(pseudo_octave_double));
   }

   // 4) grab the coprimer callable once
   if (!cpp_first_coprime) {
     cpp_first_coprime = (first_coprime_t)
     R_GetCCallable("coprimer", "first_coprime");
   }

   // 5) single, vectorized call into coprimer
   DataFrame df = cpp_first_coprime(wrap(pseudo_x),
                                    wrap(uvec),
                                    wrap(uvec));

   // 6) augment only with pseudo outputs
   df["pseudo_x"]      = pseudo_x;
   df["pseudo_octave"] = NumericVector(n, pseudo_octave_double);

   return df;
 }

 //' Compute Beats and Sidebands Separately
 //'
 //' For each unordered pair of input frequencies, compute:
 //'   1. The beat frequency (|f2 - f1|) if it's below the minimum frequency
 //'   2. Two sidebands: fi ± |f2 - f1|
 //'
 //' Returns two separate data frames: one for beats and one for sidebands.
 //'
 //' @param frequency NumericVector of input frequencies
 //' @param amplitude NumericVector of input amplitudes (same length)
 //' @return A List with two DataFrames: $beats and $sidebands
 //'
 //' @export
 // [[Rcpp::export]]
 Rcpp::List compute_beats_and_sidebands(
     Rcpp::NumericVector frequency,
     Rcpp::NumericVector amplitude
 ) {
   int n = frequency.size();
   if (n < 2) {
     return Rcpp::List::create(
       _["beats"] = Rcpp::DataFrame::create(
         _["frequency"] = Rcpp::NumericVector(),
         _["amplitude"] = Rcpp::NumericVector()
       ),
       _["sidebands"] = Rcpp::DataFrame::create(
         _["frequency"] = Rcpp::NumericVector(),
         _["amplitude"] = Rcpp::NumericVector()
       )
     );
   }

   double min_freq = Rcpp::min(frequency);
   int max_pairs   = n * (n - 1) / 2;
   int max_entries = max_pairs * 3;

   Rcpp::NumericVector beat_freqs(max_pairs);
   Rcpp::NumericVector beat_amps (max_pairs);
   Rcpp::NumericVector sb_freqs  (max_entries);
   Rcpp::NumericVector sb_amps   (max_entries);

   int beat_count = 0;
   int sb_count   = 0;

   for (int i = 0; i < n; ++i) {
     double fi = frequency[i];
     for (int j = i + 1; j < n; ++j) {
       double fj = frequency[j];
       double diff = std::abs(fi - fj);
       double sum_amp = amplitude[i] + amplitude[j];

       double tol = std::numeric_limits<double>::epsilon() *
         std::max(std::abs(fi), std::abs(fj));

       if (diff > tol && diff < min_freq) {
         // Beat
         beat_freqs[beat_count] = diff;
         beat_amps [beat_count] = sum_amp;
         ++beat_count;

         // Upper sideband
         double sb_p = fi + diff;
         if (sb_p > tol) {
           sb_freqs[sb_count] = sb_p;
           sb_amps [sb_count] = sum_amp;
           ++sb_count;
         }

         // Lower sideband
         if (fi > diff + tol) {
           double sb_m = fi - diff;
           sb_freqs[sb_count] = sb_m;
           sb_amps [sb_count] = sum_amp;
           ++sb_count;
         }
       }
     }
   }

   // Guard against Rcpp::Range(0, -1) for empty results
   Rcpp::NumericVector beat_freq_out = (beat_count > 0) ?
   beat_freqs[Rcpp::Range(0, beat_count - 1)] :
     Rcpp::NumericVector();

   Rcpp::NumericVector beat_amp_out = (beat_count > 0) ?
   beat_amps[Rcpp::Range(0, beat_count - 1)] :
     Rcpp::NumericVector();

   Rcpp::NumericVector sb_freq_out = (sb_count > 0) ?
   sb_freqs[Rcpp::Range(0, sb_count - 1)] :
     Rcpp::NumericVector();

   Rcpp::NumericVector sb_amp_out = (sb_count > 0) ?
   sb_amps[Rcpp::Range(0, sb_count - 1)] :
     Rcpp::NumericVector();

   return Rcpp::List::create(
     _["beats"] = Rcpp::DataFrame::create(
       _["frequency"] = beat_freq_out,
       _["amplitude"] = beat_amp_out
     ),
     _["sidebands"] = Rcpp::DataFrame::create(
       _["frequency"] = sb_freq_out,
       _["amplitude"] = sb_amp_out
     )
   );
 }
