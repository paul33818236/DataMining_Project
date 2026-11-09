# Pure interval memoization for a single bound series. No cost approximation.
cache_segment_cost = function(x, cost) {
  force(cost)
  original = x
  cache = new.env(hash = TRUE, parent = emptyenv())
  function(x, s = 1, e = if (is.data.frame(x)) nrow(x)+1 else length(x)+1) {
    stopifnot(identical(x, original))
    key = paste(s, e, sep = ":")
    if (exists(key, envir = cache, inherits = FALSE)) return(cache[[key]])
    value = cost(x, s, e)
    cache[[key]] = value
    value
  }
}
