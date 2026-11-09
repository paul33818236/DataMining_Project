# Author-style recursion with coarse-to-fine release of suppressed candidates.
# This extends Algorithm 2; it is not claimed to be the unchanged Algorithm 2.
source("r_extension/score_refinements.R")
scoth_delayed_partitions = function(threshold, nb_levels=10, changepoint_gain,
                                   cost_initial, x, cost_func,
                                   release_level=3L, min_distance=3L) {
  stopifnot(release_level>=1, nb_levels>=1, threshold>0, threshold<=1)
  n=length(changepoint_gain)+1L
  if (max(changepoint_gain)<threshold) {
    partition=data.frame(s=1,e=n+1,cost=cost_initial)
    return(list(partitions=rep(list(partition),nb_levels),
                changepoint_gains=rep(list(changepoint_gain),nb_levels)))
  }
  mask=thin_change_scores(changepoint_gain,min_distance)>0
  gains=list(); partitions=list()
  gains[[1]]=changepoint_gain
  if (release_level>1) gains[[1]][!mask]=0
  partitions[[1]]=scoth:::get_partition_from_changepoint_gain(gains[[1]],x,cost_func,1,n+1,threshold)
  if (nb_levels>1) for (level in 2:nb_levels) {
    gains[[level]]=scoth:::iterate_changepoint_gain_from_partition(
                       partitions[[level-1]],changepoint_gain,cost_initial)
    if (level<release_level) {
      # NA marks already selected cuts; those are always preserved.
      blocked=!mask & !is.na(gains[[level]])
      gains[[level]][blocked]=0
    }
    partitions[[level]]=scoth:::get_partition_from_changepoint_gain(
                     gains[[level]],x,cost_func,1,n+1,threshold)
  }
  list(partitions=partitions,changepoint_gains=gains)
}

delayed_selection_grid = function(scoring,thresholds,nb_levels,cost_initial,cost_func,x,release_level) {
  output=list()
  for (threshold in thresholds) {
    raw=scoth_delayed_partitions(threshold,nb_levels,scoring$score,cost_initial,x,cost_func,release_level)
    output[[length(output)+1]]=scoth:::convert_partitions_to_data_frame(threshold,raw,scoring)
  }
  scoth:::pipeline_selection_single_post_process(output,scoring,nb_levels,cost_initial,0,x)
}
