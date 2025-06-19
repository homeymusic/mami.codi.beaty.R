#include <Rcpp.h>
#include <R_ext/Rdynload.h>
using namespace Rcpp;

typedef SEXP (*coprimer_first_coprime_t)(SEXP,SEXP,SEXP);
static coprimer_first_coprime_t coprimer_first_coprime = nullptr;

 //' compute_pseudo_octave
 //'
 //' Find the pseudo octave
 //'
 //' @param ratio_n ratio to eval
 //' @param ratio_0 ratio
 //' @param n  harmonic number
 //'
 //' @return Calculated pseudo octave
 //'
 //' @export
 // [[Rcpp::export]]
 const double compute_pseudo_octave(const double ratio_n, const double ratio_0, const int n) {
   if (n==1) {
     return 1.0;
   } else {
     const int tol = 1000000;
     return std::round(tol * pow(2, log(ratio_n / ratio_0) / log(n))) / tol;
   }
 }

 //' approximate_harmonics
 //'
 //' Determine pseudo octave of all tones
 //'
 //' @param x Chord tones
 //' @param deviation Deviation for estimating least common multiples
 //'
 //' @return A double of the best guess of the pseudo octave
 //'
 //' @export
 // [[Rcpp::export]]
 DataFrame approximate_harmonics(const NumericVector x,
                                 const double deviation) {
   const int x_size   = x.size();
   const double ratio_max = max(x);
   NumericVector harmonic_number(x_size * x_size * x_size);
   NumericVector evaluation_ratio(x_size * x_size * x_size);
   NumericVector reference_ratio(x_size * x_size * x_size);
   NumericVector reference_amp(x_size * x_size * x_size);
   NumericVector pseudo_octave(x_size * x_size * x_size);
   NumericVector highest_ratio(x_size * x_size * x_size);


   const DataFrame default_pseudo_octave = DataFrame::create(
     _("harmonic_number") = 1,
     _("evaluation_ratio") = ratio_max,
     _("reference_ratio")  = ratio_max,
     _("pseudo_octave")   = 2.0,
     _("highest_ratio")    = ratio_max
   );

   if (x_size <= 2) {
     return default_pseudo_octave;
   }

   int num_matches=0;

   for (int eval_ratio_index = 0; eval_ratio_index < x_size; ++eval_ratio_index) {
     for (int ref_ratio_index = 0; ref_ratio_index < x_size; ++ref_ratio_index) {
       for (int harmonic_num = 2; harmonic_num <= x_size; ++harmonic_num) {
         const double p_octave = compute_pseudo_octave(x[eval_ratio_index], x[ref_ratio_index], harmonic_num);
         if (2.0 - deviation < p_octave && p_octave < 2.0 + deviation) {
           harmonic_number[num_matches] = harmonic_num;
           evaluation_ratio[num_matches] = x[eval_ratio_index];
           reference_ratio[num_matches]  = x[ref_ratio_index];
           highest_ratio[num_matches]    = ratio_max;
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
                                             _("evaluation_ratio") = evaluation_ratio[Rcpp::Range(0, num_matches-1)],
                                                                                   _("reference_ratio")  = reference_ratio[Rcpp::Range(0, num_matches-1)],
                                                                                                                        _("pseudo_octave")   = pseudo_octave[Rcpp::Range(0, num_matches-1)],
                                                                                                                                                            _("highest_ratio")    = highest_ratio[Rcpp::Range(0, num_matches-1)]
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
   DataFrame harmonics = approximate_harmonics(x, deviation);
   double pseudo_octave_double = pseudo_octave(harmonics["pseudo_octave"]);

   // 3) build the vectors we'll pass to coprimer
   NumericVector pseudo_x(n), uncertainties(n, uncertainty);
   for (int i = 0; i < n; ++i) {
     pseudo_x[i] = std::pow(2.0,
                            std::log(x[i]) / std::log(pseudo_octave_double));
   }

   // 4) grab the coprimer callable once
   if (!coprimer_first_coprime) {
     coprimer_first_coprime = (coprimer_first_coprime_t)
     R_GetCCallable("coprimer", "first_coprime");
   }

   // 5) single, vectorized call into coprimer
   DataFrame df = coprimer_first_coprime(wrap(pseudo_x),
                                         wrap(uncertainties),
                                         wrap(uncertainties));

   // 6) augment only with pseudo outputs
   df["pseudo_x"]      = pseudo_x;
   df["pseudo_octave"] = NumericVector(n, pseudo_octave_double);

   return df;
 }

 //' compute_sidebands_wavelength
 //'
 //' For each unordered pair of input wavelengths, compute the spatial beat‐
 //' wavelength:
 //'   λ_beat = λ_i * λ_j / |λ_j - λ_i|
 //'
 //' @param wavelength NumericVector of input wavelengths
 //' @param amplitude  NumericVector of input amplitudes (same length)
 //' @return DataFrame with columns `wavelength` and `amplitude`
 //' @export
 // [[Rcpp::export]]
 DataFrame compute_sidebands_wavelength(
     NumericVector wavelength,
     NumericVector amplitude
 ) {
   int n = wavelength.size();
   if (n < 2) {
     return DataFrame::create(
       _["wavelength"] = NumericVector(),
       _["amplitude"]  = NumericVector()
     );
   }

   // We'll only accept beat‐wavelengths longer than the longest stimulus wave
   double max_wav = Rcpp::max(wavelength);
   int max_pairs = n * (n - 1) / 2;
   int max_entries = max_pairs;        // one beat per unordered pair

   NumericVector sb_wavs(max_entries);
   NumericVector sb_amps(max_entries);
   int sb_count = 0;

   for (int i = 0; i < n; ++i) {
     double wi = wavelength[i];
     for (int j = i + 1; j < n; ++j) {
       double wj      = wavelength[j];
       double diff    = std::abs(wj - wi);
       double sum_amp = amplitude[i] + amplitude[j];
       // avoid division by zero or floating‐point noise
       double tol = std::numeric_limits<double>::epsilon() * std::max(std::abs(wi), std::abs(wj));

       if (diff > tol) {
         // spatial‐beat wavelength:
         double sb = (wi * wj) / diff;
         // only keep beats *longer* than any stimulus wavelength
         if (sb > max_wav + tol) {
           sb_wavs[sb_count] = sb;
           sb_amps[sb_count] = sum_amp;
           ++sb_count;
         }
       }
     }
   }

   // slice out only the entries we filled
   NumericVector wav_out = (sb_count > 0)
     ? sb_wavs[Range(0, sb_count - 1)]
   : NumericVector();
   NumericVector amp_out = (sb_count > 0)
     ? sb_amps[Range(0, sb_count - 1)]
   : NumericVector();

   return DataFrame::create(
     _["wavelength"] = wav_out,
     _["amplitude"]  = amp_out
   );
 }
