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
 DataFrame approximate_harmonics(const NumericVector input_ratios,
                                 const double integer_harmonic_tolerance) {
   int ratio_vector_size = input_ratios.size();
   double highest_input_ratio = max(input_ratios);

   DataFrame default_output = DataFrame::create(
     _("harmonic_number")   = 1,
     _("evaluation_ratio")  = highest_input_ratio,
     _("reference_ratio")   = highest_input_ratio,
     _("pseudo_octave")     = 2.0,
     _("highest_ratio")     = highest_input_ratio
   );
   if (ratio_vector_size <= 2) {
     return default_output;
   }

   std::vector<double> log_input_ratios(ratio_vector_size);
   for (int idx = 0; idx < ratio_vector_size; ++idx) {
     log_input_ratios[idx] = std::log(input_ratios[idx]);
   }

   std::vector<int>      harmonic_number_matches;
   std::vector<double>   evaluation_ratios;
   std::vector<double>   reference_ratios;
   std::vector<double>   pseudo_octave_values;
   std::vector<double>   highest_ratio_flags;

   harmonic_number_matches.reserve(ratio_vector_size * ratio_vector_size / 2);
   evaluation_ratios     .reserve(ratio_vector_size * ratio_vector_size / 2);
   reference_ratios      .reserve(ratio_vector_size * ratio_vector_size / 2);
   pseudo_octave_values  .reserve(ratio_vector_size * ratio_vector_size / 2);
   highest_ratio_flags   .reserve(ratio_vector_size * ratio_vector_size / 2);

   for (int i = 0; i < ratio_vector_size; ++i) {
     for (int j = i + 1; j < ratio_vector_size; ++j) {
       bool i_is_larger = (input_ratios[i] >= input_ratios[j]);
       int  idx_large   = i_is_larger ? i : j;
       int  idx_small   = i_is_larger ? j : i;
       double evaluation_ratio_value = input_ratios[idx_large];
       double reference_ratio_value  = input_ratios[idx_small];
       double log_ratio_difference   = log_input_ratios[idx_large]
       - log_input_ratios[idx_small];
       double ratio_value            = std::exp(log_ratio_difference);
       int    harmonic_candidate     = int(std::round(ratio_value));

       if (harmonic_candidate >= 2 &&
           std::abs(ratio_value - harmonic_candidate) / harmonic_candidate < integer_harmonic_tolerance) {
         double pseudo_octave_value = std::pow(
           2.0,
           log_ratio_difference / std::log((double)harmonic_candidate)
         );

         harmonic_number_matches.push_back(harmonic_candidate);
         evaluation_ratios     .push_back(evaluation_ratio_value);
         reference_ratios      .push_back(reference_ratio_value);
         pseudo_octave_values  .push_back(pseudo_octave_value);
         highest_ratio_flags   .push_back(highest_input_ratio);
       }
     }
   }

   if (harmonic_number_matches.empty()) {
     return default_output;
   }

   return DataFrame::create(
     _("harmonic_number")   = harmonic_number_matches,
     _("evaluation_ratio")  = evaluation_ratios,
     _("reference_ratio")   = reference_ratios,
     _("pseudo_octave")     = pseudo_octave_values,
     _("highest_ratio")     = highest_ratio_flags
   );
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
