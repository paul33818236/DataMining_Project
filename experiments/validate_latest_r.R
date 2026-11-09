# Latest-only synthetic comparison with the original R linear method.
library(scoth)
library(dplyr)
source("r_extension/impulse_linear_cost.R")
source("r_extension/delayed_thresholds.R")
source("r_extension/cached_cost.R")
smoke="--smoke" %in% commandArgs(trailingOnly=TRUE)
root=if (smoke) "results/latest_r/smoke_stress" else "results/latest_r/stress"
dir.create(root,recursive=TRUE,showWarnings=FALSE)
seeds=if (smoke) 203100L else 203100:203119
rows=list()
for (scenario in c("spikes1","spikes5","short3","nearby_changes")) {
  for (seed in seeds) {
    set.seed(seed)
    mu=rep(0,300);mu[101:200]=4;truth=c(101L,201L)
    if (scenario=="short3") { mu[]=0;mu[150:152]=4;truth=c(150L,153L) }
    if (scenario=="nearby_changes") { mu[]=0;mu[100:102]=4;mu[120:122]=4;truth=c(100L,103L,120L,123L) }
    x=mu+rnorm(300)
    if (scenario %in% c("spikes1","spikes5")) {
      count=if (scenario=="spikes1") 3 else 15
      idx=sample.int(300,count)
      x[idx]=x[idx]+sample(c(-1,1),count,replace=TRUE)*20
    }
    for (method in c("OriginalLinear","Delayed3")) {
      raw_cost=if (method=="OriginalLinear") scoth:::c_reg_cusum_L2 else make_impulse_linear_cost(x,4)
      cost=cache_segment_cost(x,raw_cost)
      scores=scoth_scoring_func(x,cost,FALSE)
      scoring=data.frame(index=2:length(x),score=scores$changepoint_gain)
      if (method=="Delayed3") selected=delayed_selection_grid(scoring,c(.09,.1),10,scores$cost_initial,cost,x,3)
      else selected=scoth:::pipeline_selection_single_scoring(scoring,c(.09,.1),10,scores$cost_initial,cost,x)
      current=list()
      for (i in seq_len(nrow(selected))) {
        if (!selected$selection_threshold_included[i] %in% c(.09,.1)) next
        b=selected$selection[[i]];b$groundtruth=as.integer(b$index %in% truth)
        m=scoth:::metrics_F1_func(b)
        current[[length(current)+1]]=data.frame(threshold=selected$selection_threshold_included[i],
          level=selected$selection_level[i],F1=m$F1,FP=m$nb_pred-m$TP,FN=m$nb_gt-m$TP)
      }
      df=bind_rows(current)
      for (rule in c("Fixed10","Fixed1","OracleLevel")) {
        if (rule=="OracleLevel") chosen=df %>% filter(near(threshold,.09)) %>% arrange(desc(F1),level) %>% slice(1)
        else chosen=df %>% filter(near(threshold,.1),level==if (rule=="Fixed10") 10 else 1)
        stopifnot(nrow(chosen)==1)
        chosen$scenario=scenario;chosen$seed=seed;chosen$method=method;chosen$rule=rule
        rows[[length(rows)+1]]=chosen
      }
    }
  }
  cat(paste0("LATEST_STRESS ",scenario,"\n"))
}
df=bind_rows(rows)
if (smoke) {
  reference=read.csv("results/latest_r/stress/runs.csv") %>% filter(seed %in% seeds) %>%
    arrange(scenario,seed,method,rule)
  actual=df %>% arrange(scenario,seed,method,rule)
  stopifnot(isTRUE(all.equal(reference[,names(actual)],actual,tolerance=1e-10,check.attributes=FALSE)))
}
write.csv(df,file.path(root,"runs.csv"),row.names=FALSE)
write.csv(df %>% group_by(scenario,method,rule) %>% summarize(seeds=n(),F1_mean=mean(F1),
  FP_mean=mean(FP),FN_mean=mean(FN),.groups="drop"),file.path(root,"summary.csv"),row.names=FALSE)
cat("LATEST_STRESS_FINISHED\n")
