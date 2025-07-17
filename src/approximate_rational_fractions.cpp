// This is c++ code used by mami.codi.beaty

#include <Rcpp.h>
#include <R_ext/Rdynload.h>
using namespace Rcpp;

#define DIMENSION_TIME  "time"
#define DIMENSION_SPACE "space"

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
  auto check_finite = [&](const NumericVector &v, const char *name) {
    for (int i = 0; i < v.size(); ++i) {
      double val = v[i];
      if (!std::isfinite(val)) {
        Rcpp::stop("`%s` contains non‐finite at row %d: %g", name, i+1, val);
      }
    }
  };

  // check every numeric column
  check_finite(approximations, "approximation");
  check_finite(x,              "x");
  check_finite(errors,         "error");
  check_finite(minkowski,      "minkowski");
  check_finite(entropy,        "entropy");
  check_finite(thomae,         "thomae");
  check_finite(euclids_orchard_height, "euclids_orchard_height");
  check_finite(uncertainty,    "uncertainty");

  // if we get here, everything is good
  return DataFrame::create(
    _["num"]                   = nums,
    _["den"]                   = dens,
    _["approximation"]         = approximations,
    _["x"]                     = x,
    _["error"]                 = errors,
    _["minkowski"]             = minkowski,
    _["entropy"]               = entropy,
    _["thomae"]                = thomae,
    _["euclids_orchard_height"]= euclids_orchard_height,
    _["depth"]                 = depths,
    _["path"]                  = paths,
    _["uncertainty"]           = uncertainty
  );
}

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
                              const NumericVector& uncertainty) {
   int n = x.size();
   IntegerVector nums(n), dens(n), depths(n);
   NumericVector approximations(n), errors(n), minkowski(n), entropy(n), thomae(n), euclids_orchard_height(n);
   CharacterVector paths(n);

   const int MAX_ITER = 10000;

   for (int i = 0; i < n; ++i) {
     double ideal = round_to_precision(x[i]);
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

     while ((
         std::abs(ideal - approximation) >= uncertainty[i]
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
   return rational_fraction_dataframe(
     nums, dens, approximations,
     x, errors, minkowski, entropy, thomae, euclids_orchard_height,
     depths, paths, uncertainty
   );
 }

 //' approximate_rational_fractions
 //'
 //' Approximates floating-point numbers to arbitrary uncertainty.
 //'
 //' @param x Vector of floating point numbers to approximate
 //' @param x_ref Reference value (frequency or wavelength)
 //' @param uncertainty Precision for finding rational fractions
 //'
 //' @return A data frame of rational numbers and metadata
 //' @export
 // [[Rcpp::export]]
 DataFrame approximate_rational_fractions(NumericVector& x,
                                          const double x_ref,
                                          const double uncertainty,
                                          std::string dimension) {

   int n = x.size();
   if (n == 0) {
     return DataFrame::create();
   }

   // compute ratios relative to x_ref
   NumericVector targets(n), uncertainties(n),  harmonic_ratios(n);

   for (int i = 0; i < n; ++i) {
     double tone_ratio = x[i] / x_ref;

     Rcpp::Rcout
     << "i=" << i
     << "  tone_ratio="
     << std::setprecision(std::numeric_limits<double>::max_digits10)
     << tone_ratio
     << std::endl;


     if (dimension == DIMENSION_TIME) {
       double harmonic_ratio;
       if (tone_ratio >= 1.0) {
         harmonic_ratio = std::round(round_to_precision(tone_ratio, 2));
       } else {
         harmonic_ratio = 1.0 / std::round(1.0/round_to_precision(tone_ratio,2));
       }
       targets[i] = tone_ratio / harmonic_ratio;
       uncertainties[i] = uncertainty;
       harmonic_ratios[i] = harmonic_ratio;
     } else if (dimension == DIMENSION_SPACE) {
       double harmonic_ratio;
       if (tone_ratio >= 1.0) {
         harmonic_ratio = 1.0 / std::round(round_to_precision(tone_ratio, 2));
       } else {
         harmonic_ratio = std::round(1.0 / round_to_precision(tone_ratio, 2));
       }
       targets[i] = tone_ratio * harmonic_ratio;
       uncertainties[i] = uncertainty * harmonic_ratio * harmonic_ratio;
       harmonic_ratios[i] = harmonic_ratio;
     } else {
       Rcpp::stop("Invalid dimension: `%s`", dimension);
     }
   }

   DataFrame df = rational_fractions(
     targets,
     uncertainties
   );

   df["harmonic_ratio"]  = harmonic_ratios;

   return df;
 }
