# Fixed noise estimation and isolated impulse repair used by Delayed3.
estimate_refined_noise = function(x) {
  x = as.numeric(x)
  d = diff(x)
  first = if (length(d)) median(abs(d-median(d)))/(qnorm(.75)*sqrt(2)) else 0
  numerical_floor = 1e-8*max(1, diff(range(x)))
  if (first > numerical_floor) return(first)
  # Quantized/constant differences can have zero MAD. Use the observed
  # smallest positive resolution as a conservative fallback, not 1e-8 alone.
  jumps = abs(d[abs(d) > numerical_floor])
  resolution = if (length(jumps)) min(jumps)/sqrt(12) else 0
  max(first, resolution, numerical_floor)
}

repair_isolated_impulses = function(x, k = 4, neighbor_k = 2.5, max_fraction = .02) {
  repair_vector = function(z) {
    z = as.numeric(z)
    n = length(z)
    if (n < 5) return(z)
    sigma = estimate_refined_noise(z)
    idx = 2:(n-1)
    interpolation = (z[idx-1]+z[idx+1])/2
    candidate = abs(z[idx]-interpolation) > k*sigma &
      abs(z[idx-1]-z[idx+1]) <= neighbor_k*sigma &
      sign(z[idx]-z[idx-1]) == sign(z[idx]-z[idx+1])
    flags = rep(FALSE, n); flags[idx] = candidate
    # Protect adjacent events: only an isolated one-sample excursion is repaired.
    isolated = idx[flags[idx] & !flags[idx-1] & !flags[idx+1]]
    if (length(isolated) > max_fraction*n) return(z)
    result = z
    result[isolated] = (z[isolated-1]+z[isolated+1])/2
    result
  }
  if (is.data.frame(x)) return(as.data.frame(lapply(x, repair_vector)))
  repair_vector(x)
}

