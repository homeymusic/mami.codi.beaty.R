// This is c++ code used by mami.codi.beaty

#include <Rcpp.h>
#include <R_ext/Rdynload.h>
using namespace Rcpp;

// [[Rcpp::export]]
double approximate_pseudo_octave(Rcpp::NumericVector unsorted_ratios,
                                 const double uncertainty) {
  int n = unsorted_ratios.size();
  if (n <= 2) return 2.0;

  // Copy into our working 'ratios' and sort
  std::vector<double> ratios(unsorted_ratios.begin(), unsorted_ratios.end());
  std::sort(ratios.begin(), ratios.end());

  // Precompute log2 of each ratio
  std::vector<double> log2_ratios(n);
  for (int i = 0; i < n; ++i) {
    log2_ratios[i] = std::log2(ratios[i]);
  }

  double log2_uncertainty = std::log2(1.0 + uncertainty);

  std::vector<double> candidates;
  candidates.reserve(n * (n - 1) / 2);

  for (int i = 0; i < n; ++i) {
    for (int j = i + 1; j < n; ++j) {
      double log_diff      = log2_ratios[j] - log2_ratios[i];
      double approximation = std::exp2(log_diff);
      int    ideal         = int(std::round(approximation));

      if (ideal >= 2 &&
          std::abs(ideal - approximation) / ideal < log2_uncertainty) {
        double oct = std::exp2(log_diff / std::log2((double)ideal));
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
            [&](int a, int b){ return counts[a] > counts[b]; });

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
   NumericVector approximations(n), errors(n), thomae(n), euclids_orchard_height(n);
   CharacterVector paths(n);

   const int MAX_ITER = 10000;

   for (int i = 0; i < n; ++i) {
     double ideal = round_to_precision(x[i] / x_ref);
     std::vector<char> path;
     // Initialize Stern–Brocot endpoints
     int left_num = 0, left_den = 1;
     int right_num = 1, right_den = 0;

     // First approximation
     int approximation_num = left_num + right_num;
     int approximation_den = left_den + right_den;
     double approximation = round_to_precision(
       static_cast<double>(approximation_num) / approximation_den
     );

     int iter = 1;

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
   double pseudo_octave = approximate_pseudo_octave(ratios, uncertainty);

   // build the transformed vector for coprime search
   NumericVector pseudo_x(n), uncertainties(n, uncertainty);
   for (int i = 0; i < n; ++i) {
     pseudo_x[i] = x_ref * std::pow(2.0,
                            std::log(ratios[i]) /
                              std::log(pseudo_octave));
   }

   DataFrame df = rational_fractions(
     pseudo_x,
     x_ref,
     uncertainty
   );

   df["pseudo_x"]    = pseudo_x;
   df["pseudo_octave"] = NumericVector(n, pseudo_octave);

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

 //' Compute distortion (cubic) products
 //'
 //' For each unordered pair, compute dp = 2*min(fi,fj) – max(fi,fj)
 //' and amplitude = 0.5 * amplitude_of_the_lower_tone.
 //'
 //' @param frequency NumericVector of input frequencies
 //' @param amplitude NumericVector of input amplitudes
 //' @return DataFrame with columns `frequency` and `amplitude`
 //' @export
 // [[Rcpp::export]]
 DataFrame compute_distortion_products(
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

   int maxPairs   = n * (n - 1) / 2;
   NumericVector outFreqs(maxPairs);
   NumericVector outAmps (maxPairs);
   int count = 0;

   for (int i = 0; i < n; ++i) {
     double fi = frequency[i];
     double Ai = amplitude[i];
     for (int j = i + 1; j < n; ++j) {
       double fj = frequency[j];
       double Aj = amplitude[j];

       // identify lower and higher
       double f_low  = fi < fj ? fi : fj;
       double f_high = fi < fj ? fj : fi;
       double A_low  = fi < fj ? Ai : Aj;

       // primary distortion product: 2*f_low - f_high
       double dp = 2.0 * f_low - f_high;
       if (dp > 0) {
         outFreqs[count] = dp;
         outAmps [count] = 0.5 * A_low;
         ++count;
       }
     }
   }

   if (count == 0) {
     return DataFrame::create(
       _["frequency"] = NumericVector(),
       _["amplitude"] = NumericVector()
     );
   }

   // trim to actual length
   NumericVector freqOut = outFreqs[ Range(0, count - 1) ];
   NumericVector ampOut  = outAmps [ Range(0, count - 1) ];

   return DataFrame::create(
     _["frequency"] = freqOut,
     _["amplitude"] = ampOut
   );
 }
