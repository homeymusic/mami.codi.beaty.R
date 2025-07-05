// This is c++ code used by mami.codi.beaty

#include <Rcpp.h>
#include <R_ext/Rdynload.h>
using namespace Rcpp;

DataFrame rational_fraction_dataframe(const IntegerVector &nums,
                                      const IntegerVector &dens,
                                      const NumericVector &approximations,
                                      const NumericVector &x,
                                      const NumericVector &errors,
                                      const NumericVector &minkowski,
                                      const NumericVector &entropy,
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
                           _["minkowski"] = minkowski,
                           _["entropy"] = entropy,
                           _["thomae"] = thomae,
                           _["euclids_orchard_height"] = euclids_orchard_height,
                           _["depth"] = depths,
                           _["path"] = paths,
                           _["uncertainty"] = uncertainty);
}

// forward declaration of round_to_precision
inline double round_to_precision(double value, int precision = 15) {
  double scale = std::pow(10.0, precision);
  return std::round(value * scale) / scale;
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
   NumericVector approximations(n), errors(n), minkowski(n), entropy(n), thomae(n), euclids_orchard_height(n);
   CharacterVector paths(n);

   const int MAX_ITER = 10000;

   for (int i = 0; i < n; ++i) {
     double ideal = round_to_precision(x[i] / x_ref);
     std::vector<char> path;
     // Initialize Stern–Brocot endpoints
     int left_num = -1, left_den = 0;
     int approximation_num = 0, approximation_den = 1;
     int right_num = 1, right_den = 0;

     // First approximation
     double approximation = round_to_precision(
       static_cast<double>(approximation_num) / approximation_den
     );

     int iter = 0;

     // continue while |x/x_ref - num/den| >= uncertainty
     while ((
         std::abs(ideal - approximation) >= uncertainty
     ) && iter < MAX_ITER) {
       if (approximation < ideal) {
         left_num = approximation_num;  left_den = approximation_den;
         path.push_back('R');
       } else {
         right_num = approximation_num; right_den = approximation_den;
         path.push_back('L');
       }
       approximation_num = left_num + right_num;
       approximation_den = left_den + right_den;
       if (approximation_den == 0) break;
       approximation = round_to_precision(
         static_cast<double>(approximation_num) / approximation_den
       );
       ++iter;
     }
     if (iter >= MAX_ITER) {
       Rcpp::warning("rational_fractions: max iterations (%d) reached at index %d", MAX_ITER, i);
     }

     nums[i]           = approximation_num;
     dens[i]           = approximation_den;
     approximations[i] = approximation;
     errors[i]         = round_to_precision(approximation - ideal);
     depths[i]         = iter;
     // Build a simple path string of R/L moves
     paths[i]          = (iter < MAX_ITER
                            ? std::string(path.begin(), path.end())
                              : std::string());

     // Compute Minkowski question-mark ?(x) directly from the SB path
     double qm_val = 0.0;
     double weight = 0.5;
     for (char c : path) {
       if (c == 'R') qm_val += weight;
       weight *= 0.5;
     }
     minkowski[i] = qm_val;

     // count R’s and L’s
     int countR = std::count(paths[i].begin(), paths[i].end(), 'R');
     int countL = std::count(paths[i].begin(), paths[i].end(), 'L');
     int total  = countR + countL;

     double H = 0.0;
     if (total > 0) {
       double pR = double(countR) / total;
       double pL = double(countL) / total;
       H = 0.0;
       if (pR > 0) H -= pR * std::log2(pR);
       if (pL > 0) H -= pL * std::log2(pL);
     }
     entropy[i] = H;

     thomae[i]         = (approximation_den ? 1.0 / approximation_den : NA_REAL);
     euclids_orchard_height[i]
     = (approximation_den
          ? 1.0 / (std::abs(approximation_num) + approximation_den)
          : NA_REAL);
   }

   // pack constant uncertainty vector
   NumericVector unc(n, uncertainty);
   return rational_fraction_dataframe(
     nums, dens, approximations,
     x, errors, minkowski, entropy, thomae, euclids_orchard_height,
     depths, paths, unc
   );
 }

// -------------------------------------------------------------------------
// Helper: approximate a single real ratio by a coprime fraction via SB
// -------------------------------------------------------------------------
inline double approximate_fraction(const double ratio,
                                   const double uncertainty) {
  // 1-element vector [ratio], reference = 1.0
  NumericVector v = NumericVector::create(ratio);
  DataFrame df   = rational_fractions(v, 1.0, uncertainty);
  // pull out the one approximation
  return as<NumericVector>(df["approximation"])[0];
}

// -------------------------------------------------------------------------
// pure SB-based pseudo-octave
// -------------------------------------------------------------------------
// [[Rcpp::export]]
double approximate_pseudo_octave(const double harmonic_ratio,
                                 const double uncertainty) {

  int ideal_harmonic = int(std::round(harmonic_ratio));
  if (ideal_harmonic < 2 ||
      std::abs(harmonic_ratio - ideal_harmonic)/ideal_harmonic >= uncertainty) {
    return 2.0;
  }

  // double frac = approximate_fraction(harmonic_ratio, uncertainty);
  return std::exp2(std::log2(harmonic_ratio) / std::log2(harmonic_ratio));

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
   int n = x.size();
   if (n == 0) {
     return DataFrame::create();
   }

   // find the pseudo-octave in ratio-space
   NumericVector ratios(n), pseudo_octaves(n), pseudo_x(n);
   for (int i = 0; i < n; ++i) {
     double ratio = x[i] / x_ref;
     double pseudo_octave = approximate_pseudo_octave(ratio, uncertainty);
     if (std::isnan(pseudo_octave)) {
       Rcpp::stop("pseudo_octave is NaN at index %d (ratio = %g)", i+1, ratio);
     }
     pseudo_octaves[i] = pseudo_octave;

     double this_pseudo_x = x_ref * std::exp2(std::log2(ratio) / std::log2(pseudo_octave));
     if (std::isnan(this_pseudo_x)) {
       Rcpp::stop("pseudo_x is NaN at index %d (ratio = %g, pseudo_octave = %g)",
                  i+1, ratio, pseudo_octave);
     }
     pseudo_x[i] = this_pseudo_x;
   }

   DataFrame df = rational_fractions(
     pseudo_x,
     x_ref,
     uncertainty
   );

   df["pseudo_x"]      = pseudo_x;
   df["pseudo_octave"] = pseudo_octaves;

   return df;
 }

 //' Compute cubic distortion products (2 f_low − f_high)
 //'
 //' For each unordered pair of input frequencies, compute the single
 //' lower‐order distortion product at 2 f_low − f_high.
 //'
 //' @param frequency NumericVector of input frequencies
 //' @param amplitude NumericVector of input amplitudes (same length)
 //' @return DataFrame with columns `frequency` (the DP) and `amplitude`
 //' @export
 // [[Rcpp::export]]
 DataFrame compute_cubic_distortion_products(
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

   double minFreq    = Rcpp::min(frequency);
   int    maxPairs   = n * (n - 1) / 2;
   NumericVector outFreqs(maxPairs), outAmps(maxPairs);
   int count = 0;

   constexpr double ABS_TOL = 1e-15;
   double eps = std::numeric_limits<double>::epsilon();

   for (int i = 0; i < n; ++i) {
     double fi = frequency[i];
     for (int j = i + 1; j < n; ++j) {
       double fj   = frequency[j];
       double Aj   = amplitude[j];

       // sort into low/high
       double f_low  = std::min(fi, fj);
       double f_high = std::max(fi, fj);

       // compute difference and apply tolerance + critical-band gate
       double diff = f_high - f_low;
       double tol  = std::max(ABS_TOL, eps * f_high);
       if (diff < minFreq) {
         double lower_cubic = 2.0 * f_low - f_high;
         if (lower_cubic > tol) {
           outFreqs[count] = lower_cubic;
           outAmps [count] = Aj * 0.1;
           ++count;
         }
       }
     }
   }

   // trim to actual size
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
