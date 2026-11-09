# Standalone Delayed3 experiment; reads only upstream data and latest modules.
library(scoth)
library(dplyr)
source("r_extension/impulse_linear_cost.R")
source("r_extension/delayed_thresholds.R")
source("r_extension/cached_cost.R")
args=commandArgs(trailingOnly=TRUE)
verify="--verify" %in% args
root="results/latest_r"
folder=file.path(root,"cases")
dir.create(folder,recursive=TRUE,showWarnings=FALSE)
config=list(method="Delayed3",repair_k=4,min_distance=3,release_level=3,levels=10,
  thresholds=c(seq(.03,.2,.01),.3,.4,.5,.6,.7,1),
  md5=tools::md5sum(c("r_extension/refined_costs.R","r_extension/impulse_linear_cost.R",
    "r_extension/score_refinements.R","r_extension/delayed_thresholds.R",
    "r_extension/cached_cost.R","experiments/run_latest_r.R")))
config_path=file.path(root,"configuration.RDS")
if (file.exists(config_path)) stopifnot(identical(readRDS(config_path),config))
saveRDS(config,config_path)
jsonlite::write_json(config,file.path(root,"configuration.json"),auto_unbox=TRUE,pretty=TRUE)
capture.output(sessionInfo(),file=file.path(root,"sessionInfo.txt"))
data=load_kpis("upstream/scoth-segmentation/public-data")
truths=load_groundtruths("upstream/scoth-segmentation/public-data")
stopifnot(nrow(data)==42)
all_rows=list();verified=0L
for (i in seq_len(nrow(data))) {
  name=data$dataset_name[i]
  path=file.path(folder,paste0(name,"@Delayed3.csv"))
  rds=sub(".csv$",".RDS",path)
  if (file.exists(path) && file.exists(rds) && !verify) {
    all_rows[[name]]=read.csv(path)
    next
  }
  frame=data$kpis[[i]]
  x=if (ncol(frame)==1) frame[,1] else frame
  truth=truths$groundtruth[[which(rownames(truths)==name)]]
  raw_cost=make_impulse_linear_cost(x,config$repair_k)
  cost=cache_segment_cost(x,raw_cost)
  scored=scoth_scoring_func(x,cost,FALSE)
  scores=data.frame(index=seq_along(scored$changepoint_gain)+1,score=scored$changepoint_gain)
  selected=delayed_selection_grid(scores,config$thresholds,config$levels,
    scored$cost_initial,cost,x,config$release_level)
  rows=vector("list",nrow(selected))
  for (j in seq_len(nrow(selected))) {
    b=selected$selection[[j]];b$groundtruth=as.integer(b$index %in% truth)
    m=scoth:::metrics_F1_func(b)
    rows[[j]]=data.frame(dataset=name,method="Delayed3",threshold=selected$selection_threshold_included[j],
      level=selected$selection_level[j],F1=m$F1,TP=m$TP,FP=m$nb_pred-m$TP,FN=m$nb_gt-m$TP,n_pred=m$nb_pred)
  }
  current=bind_rows(rows)
  if (verify && file.exists(path) && file.exists(rds)) {
    expected=read.csv(path)
    stopifnot(isTRUE(all.equal(expected[,names(current)],current,tolerance=1e-10,check.attributes=FALSE)))
    expected_selection=readRDS(rds)$selection
    stopifnot(identical(expected_selection$selection,selected$selection))
    verified=verified+1L
  }
  write.csv(current,path,row.names=FALSE)
  saveRDS(list(x=x,repaired_x=attr(raw_cost,"repaired_series"),scoring=scored,selection=selected,truth=truth),rds)
  all_rows[[name]]=current
  cat(sprintf("LATEST_R %d/42 %s verified=%s\n",i,name,verify))
}
all_rows=bind_rows(all_rows)
write.csv(all_rows,file.path(root,"all_settings.csv"),row.names=FALSE)
best=all_rows %>% filter(near(threshold,.09)) %>% group_by(dataset) %>%
  arrange(desc(F1),level,.by_group=TRUE) %>% slice(1) %>% ungroup()
write.csv(best,file.path(root,"best_by_dataset.csv"),row.names=FALSE)
summary=best %>% summarize(datasets=n(),F1_mean=mean(F1),F1_sd=sd(F1),FP_mean=mean(FP),FN_mean=mean(FN))
write.csv(summary,file.path(root,"summary.csv"),row.names=FALSE)
jsonlite::write_json(list(verified_against_retained_cases=verified,method="Delayed3"),
  file.path(root,"verification.json"),pretty=TRUE,auto_unbox=TRUE)
print(summary)
cat("LATEST_R_FINISHED\n")
