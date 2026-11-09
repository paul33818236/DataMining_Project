# Matched end-to-end timing: no saved scoring/partition reuse, no cost memoization.
# Each measurement includes cost preparation, author scoring and 10-level selection.
library(scoth)
library(dplyr)
source("r_extension/impulse_linear_cost.R")
source("r_extension/delayed_thresholds.R")
root="results/author_vs_latest_r"
data=load_kpis("upstream/scoth-segmentation/public-data")
run=function(x,method) {
  if (method=="Original") {
    cost=if (is.data.frame(x)) scoth:::c_reg_cusum_L2_multivariate else scoth:::c_reg_cusum_L2
    threshold=.1
  } else { cost=make_impulse_linear_cost(x,4);threshold=.09 }
  scores=scoth_scoring_func(x,cost,FALSE)
  scored=data.frame(index=seq_along(scores$changepoint_gain)+1,score=scores$changepoint_gain)
  if (method=="Original") {
    invisible(capture.output(selected<-scoth:::pipeline_selection_single_scoring(
      scored,threshold,10,scores$cost_initial,cost,x)))
  } else selected=delayed_selection_grid(scored,threshold,10,scores$cost_initial,cost,x,3)
  selected
}
set.seed(8301)
warm=c(rnorm(20),rnorm(20,3))
invisible(run(warm,"Original"));invisible(run(warm,"Delayed3"))
rows=list()
for (i in seq_len(nrow(data))) {
  name=data$dataset_name[i];frame=data$kpis[[i]]
  x=if (ncol(frame)==1) frame[,1] else frame
  for (repetition in 1:3) {
    methods=if ((i+repetition)%%2==0) c("Original","Delayed3") else c("Delayed3","Original")
    for (method in methods) {
      # Collect garbage before, outside, each timed measurement.
      invisible(gc())
      started=proc.time()[["elapsed"]]
      result=run(x,method)
      elapsed=proc.time()[["elapsed"]]-started
      stopifnot(nrow(result)==33)
      rows[[length(rows)+1]]=data.frame(dataset=name,length=nrow(frame),features=ncol(frame),
        method,repetition,seconds=elapsed)
    }
  }
  write.csv(bind_rows(rows),file.path(root,"timing_runs.csv"),row.names=FALSE)
  cat(sprintf("TIMING %d/42 %s\n",i,name))
}
df=bind_rows(rows)
per_dataset=df %>% group_by(dataset,method) %>% summarize(seconds=median(seconds),.groups="drop")
summary=per_dataset %>% group_by(method) %>% summarize(datasets=n(),
  mean_seconds=mean(seconds),median_seconds=median(seconds),total_seconds=sum(seconds),.groups="drop")
write.csv(per_dataset,file.path(root,"timing_by_dataset.csv"),row.names=FALSE)
write.csv(summary,file.path(root,"timing_summary.csv"),row.names=FALSE)
capture.output(sessionInfo(),file=file.path(root,"timing_sessionInfo.txt"))
print(summary)
cat("MATCHED_TIMING_FINISHED\n")
