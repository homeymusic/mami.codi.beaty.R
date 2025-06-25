// This is c++ code used by mami.codi.beaty

#include <Rcpp.h>
#include <R_ext/Rdynload.h>
using namespace Rcpp;

typedef SEXP (*coprimer_first_coprime_t)(SEXP,SEXP,SEXP);
static coprimer_first_coprime_t coprimer_first_coprime = nullptr;

// [[Rcpp::export]]
double approximate_pseudo_octave(const Rcpp::NumericVector& ratios,
                                 const double uncertainty) {
  int n = ratios.size();
  if (n <= 2) return 2.0;

  std::vector<double> log_ratios(n);
  for (int i = 0; i < n; ++i) {
    log_ratios[i] = std::log(ratios[i]);
  }

  double log_uncertainty = log(1 + uncertainty) / log(2);

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
          std::abs(ratio - harmonic_number) / harmonic_number < log_uncertainty) {
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

DataFrame rational_fraction_dataframe(const IntegerVector &nums,
                                      const IntegerVector &dens,
                                      const NumericVector &approximations,
                                      const NumericVector &x,
                                      const NumericVector &errors,
                                      const NumericVector &thomae,
                                      const NumericVector &euclids_orchard_height,
                                      const IntegerVector &depths,
                                      const CharacterVector &paths,
                                      const NumericVector &uncertainty) {
  return DataFrame::create(_["num"] = nums,
                           _["den"] = dens,
                           _["approximation"] = approximations,
                           _["x"] = x,
                           _["error"] = errors,
                           _["thomae"] = thomae,
                           _["euclids_orchard_height"] = euclids_orchard_height,
                           _["depth"] = depths,
                           _["path"] = paths,
                           _["uncertainty"] = uncertainty);
}

 // -------------------------------------------------------------------------
 // Main: simplified Stern–Brocot with direct uncertainty test
 // -------------------------------------------------------------------------
 //' rational_fractions
 //'
 //' Approximate each x[i]/x_ref by a coprime fraction num/den within an uncertainty.
 //'
 //' @param x Numeric vector of values to approximate.
 //' @param x_ref Reference scalar value.
 //' @param uncertainty Uncertainty threshold for |x/x_ref − num/den|.
 //' @return DataFrame with columns: num, den, approximation, x, error, thomae,
 //'         euclids_orchard_height, depth, path, uncertainty.
 //' @export
 // [[Rcpp::export]]
 DataFrame rational_fractions(const NumericVector& x,
                              double x_ref,
                              double uncertainty) {
   int n = x.size();
   IntegerVector nums(n), dens(n), depths(n);
   NumericVector approximations(n), errors(n), thomae(n), euclids_orchard_height(n);
   CharacterVector paths(n);

   std::vector<char> path;

   const int MAX_ITER = 10000;

   for (int i = 0; i < n; ++i) {
     double ratio = x[i] / x_ref;

     // Initialize Stern–Brocot endpoints
     int left_num = 0, left_den = 1;
     int right_num = 1, right_den = 0;

     // First mediant
     int mediant_num = left_num + right_num;
     int mediant_den = left_den + right_den;
     double mediant = static_cast<double>(mediant_num) / mediant_den;

     int iter = 0;

     // continue while |x/x_ref - num/den| >= uncertainty
     while ((std::abs(x[i] / x_ref
                        - static_cast<double>(mediant_num) / mediant_den)
               >= uncertainty) && iter < MAX_ITER) {
               if (mediant < ratio) {
                 left_num = mediant_num;  left_den = mediant_den;
                 path.push_back('R');
               } else {
                 right_num = mediant_num; right_den = mediant_den;
                 path.push_back('L');
               }
               mediant_num = left_num + right_num;
               mediant_den = left_den + right_den;
               if (mediant_den == 0) break;
               mediant = static_cast<double>(mediant_num) / mediant_den;
               ++iter;
     }

     nums[i]           = mediant_num;
     dens[i]           = mediant_den;
     approximations[i] = mediant;
     errors[i]         = mediant - ratio;
     depths[i]         = iter;
     // Build a simple path string of R/L moves
     paths[i]          = (iter < MAX_ITER
                            ? std::string(path.begin(), path.end())
                              : std::string());
     thomae[i]         = (mediant_den ? 1.0 / mediant_den : NA_REAL);
     euclids_orchard_height[i]
     = (mediant_den
          ? 1.0 / (std::abs(mediant_num) + mediant_den)
          : NA_REAL);
   }

   // pack constant uncertainty vector
   NumericVector unc(n, uncertainty);
   return rational_fraction_dataframe(
     nums, dens, approximations,
     x, errors, thomae, euclids_orchard_height,
     depths, paths, unc
   );
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
 DataFrame approximate_rational_fractions(NumericVector& x,
                                          const double x_ref,
                                          const double uncertainty) {
   // de-duplicate
   x = unique(x);
   int n = x.size();
   if (n == 0) {
     return DataFrame::create();
   }

   // compute ratios relative to x_ref
   NumericVector ratios(n);
   for (int i = 0; i < n; ++i) {
     ratios[i] = x[i] / x_ref;
   }

   // find the pseudo-octave in ratio-space
   double pseudo_octave_double = approximate_pseudo_octave(ratios, uncertainty);

   // build the transformed vector for coprime search
   NumericVector pseudo_x(n), uncertainties(n, uncertainty);
   for (int i = 0; i < n; ++i) {
     pseudo_x[i] = std::pow(2.0,
                            std::log(ratios[i]) /
                              std::log(pseudo_octave_double));
   }

   // resolve the first_coprime symbol if needed
   if (!coprimer_first_coprime) {
     coprimer_first_coprime = (coprimer_first_coprime_t)
     R_GetCCallable("coprimer", "first_coprime");
   }

   // call into the coprimer library
   DataFrame df = as<DataFrame>( coprimer_first_coprime(
     wrap(pseudo_x),
     wrap(uncertainties),
     wrap(uncertainties)
   ));

   // attach original data for reference
   df["x"]           = x;
   df["ratio"]       = ratios;
   df["pseudo_x"]    = pseudo_x;
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
     NumericVector& frequency,
     NumericVector& amplitude
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
