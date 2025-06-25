// This is c++ code used by mami.codi.beaty

#include <Rcpp.h>
#include <R_ext/Rdynload.h>
using namespace Rcpp;

typedef SEXP (*coprimer_first_coprime_t)(SEXP,SEXP,SEXP);
static coprimer_first_coprime_t coprimer_first_coprime = nullptr;

 // [[Rcpp::export]]
 double approximate_pseudo_octave(const Rcpp::NumericVector ratios,
                                 const double integer_harmonic_tolerance) {
  int n = ratios.size();
  if (n <= 2) return 2.0;

  std::vector<double> log_ratios(n);
  for (int i = 0; i < n; ++i) {
    log_ratios[i] = std::log(ratios[i]);
  }

  std::vector<double> candidates;
  candidates.reserve(n * (n - 1) / 2);

  for (int i = 0; i < n; ++i) {
    for (int j = i + 1; j < n; ++j) {
      bool i_larger = ratios[i] >= ratios[j];
      int  small_i  = i_larger ? j : i;
      int  large_i  = i_larger ? i : j;

      double log_diff = log_ratios[large_i] - log_ratios[small_i];
      double ratio    = std::exp(log_diff);
      int    harmonic_number = int(std::round(ratio));

      if (harmonic_number >= 2 &&
          std::abs(ratio - harmonic_number) / harmonic_number < integer_harmonic_tolerance) {
        double oct = std::pow(2.0, log_diff / std::log((double)harmonic_number));
        candidates.push_back(oct);
      }
    }
  }

  if (candidates.empty()) return 2.0;

  Rcpp::NumericVector qualifiedCandidates(candidates.begin(), candidates.end());
  Rcpp::IntegerVector counts = Rcpp::table(qualifiedCandidates);
  Rcpp::CharacterVector candidateBins = counts.names();
  Rcpp::IntegerVector idx = Rcpp::seq_along(counts) - 1;
  std::sort(idx.begin(), idx.end(),
            [&](int i, int j){ return counts[i] > counts[j]; });

  return std::stod(Rcpp::as<std::string>(candidateBins[idx[0]]));
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
   // new one-step
   double pseudo_octave_double = approximate_pseudo_octave(x, deviation);

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

 //' Compute amplitude modulation sidebands
 //'
 //' For each unordered pair of input frequencies, compute either:
 //'   • Sidebands: fi ± |fi - fj|
 //'
 //' @param frequency NumericVector of input frequencies
 //' @param amplitude NumericVector of input amplitudes (same length)
 //' @return DataFrame with columns `frequency` and `amplitude`
 //' @export
 // [[Rcpp::export]]
 DataFrame compute_amplitude_modulation(
     NumericVector frequency,
     NumericVector amplitude
 ) {
   int n = frequency.size();
   if (n < 2) {
     return DataFrame::create(
       _["frequency"] = NumericVector(),
       _["amplitude"] = NumericVector()
     );
   }

   double minFreq  = Rcpp::min(frequency);
   int    maxPairs = n * (n - 1) / 2;
   int    maxEntries = maxPairs * 2;

   NumericVector outFreqs(maxEntries);
   NumericVector outAmps (maxEntries);
   int count = 0;

   for (int i = 0; i < n; ++i) {
     double fi = frequency[i];
     for (int j = i + 1; j < n; ++j) {
       double fj  = frequency[j];
       double Aj  = amplitude[j];
       double diff = std::abs(fi - fj);

       double tol = std::numeric_limits<double>::epsilon() *
         std::max(std::abs(fi), std::abs(fj));

       if (diff > tol && diff < minFreq) {
         double ampVal = Aj * 0.5;

           // Upper sideband
           outFreqs[count] = fi + diff;
           outAmps [count] = ampVal;
           ++count;

           // Lower sideband (only if above lowest input)
           outFreqs[count] = fi - diff;
           outAmps [count] = ampVal;
           ++count;
       }
     }
   }

   // Trim to actual size
   NumericVector freqOut = (count > 0)
     ? outFreqs[ Range(0, count - 1) ]
   : NumericVector();
   NumericVector ampOut  = (count > 0)
     ? outAmps [ Range(0, count - 1) ]
   : NumericVector();

   return DataFrame::create(
     _["frequency"] = freqOut,
     _["amplitude"] = ampOut
   );
 }
