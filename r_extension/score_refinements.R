# Fixed candidate suppression used in Delayed3's coarse levels.
thin_change_scores = function(scores, min_distance = 2L) {
  stopifnot(all(is.finite(scores)), all(scores >= 0), min_distance >= 1)
  if (min_distance == 1 || length(scores) < 2) return(scores)
  output = rep(0, length(scores))
  retained = integer(0)
  for (i in order(-scores, seq_along(scores))) {
    if (scores[i] <= 0) break
    if (!length(retained) || all(abs(retained-i) >= min_distance)) {
      output[i] = scores[i]
      retained = c(retained, i)
    }
  }
  output
}

