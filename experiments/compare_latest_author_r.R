# Comprehensive, same-prediction comparison: original R versus Delayed3.
library(scoth)
library(dplyr)
library(jsonlite)
root="results/author_vs_latest_r"
dir.create(root,recursive=TRUE,showWarnings=FALSE)
original=readRDS("upstream/scoth-segmentation/output-data/summarizing_results_F1/summary.RDS") %>%
  filter(groundtruth_name=="groundtruth",cost_method=="reg_cusum_L2",near(selection_threshold_included,.1)) %>%
  transmute(dataset=dataset_name,method="OriginalLinearL2",threshold=selection_threshold_included,level=selection_level,F1) %>%
  group_by(dataset) %>% arrange(desc(F1),level,.by_group=TRUE) %>% slice(1) %>% ungroup()
latest=read.csv("results/latest_r/best_by_dataset.csv")
stopifnot(nrow(original)==42,nrow(latest)==42,all(latest$method=="Delayed3"))
truths=load_groundtruths("upstream/scoth-segmentation/public-data")
split=read.csv("experiments/data_folds.csv")
records=list()
for (pipeline in c("Original","Delayed3")) {
  chosen=if (pipeline=="Original") original else latest
  for (i in seq_len(nrow(chosen))) {
    row=chosen[i,]; name=row$dataset
    if (pipeline=="Original") {
      paths=list.files("upstream/scoth-segmentation/output-data/algorithm_selection_results",paste0("^",name,"@"),full.names=TRUE)
      df=readRDS(paths[1]) %>% filter(cost_method=="reg_cusum_L2")
    } else df=readRDS(file.path("results/latest_r/cases",paste0(name,"@Delayed3.RDS")))$selection
    selected=df %>% filter(near(selection_threshold_included,row$threshold),selection_level==row$level)
    stopifnot(nrow(selected)==1)
    gt=truths[which(rownames(truths)==name),,drop=FALSE]
    f1=scoth:::pipeline_evaluation_single_selection(selected,gt,"F1")$evaluation[[1]]$F1$groundtruth
    tcpd=scoth:::pipeline_evaluation_single_selection(selected,gt,"TCPD")$evaluation[[1]]$TCPD$groundtruth
    stopifnot(abs(f1$F1-row$F1)<1e-10)
    records[[length(records)+1]]=data.frame(dataset=name,pipeline,
      threshold=row$threshold,level=row$level,F1=f1$F1,
      TP=f1$TP,FP=f1$nb_pred-f1$TP,FN=f1$nb_gt-f1$TP,
      predictions=f1$nb_pred,truth_count=f1$nb_gt,
      F1_biased=tcpd$F1,covering=tcpd$covering)
  }
}
df=bind_rows(records)
summary=df %>% group_by(pipeline) %>% summarize(datasets=n(),F1_mean=mean(F1),F1_sd=sd(F1),
  F1_biased_mean=mean(F1_biased),F1_biased_sd=sd(F1_biased),
  covering_mean=mean(covering),covering_sd=sd(covering),
  TP_total=sum(TP),FP_total=sum(FP),FN_total=sum(FN),
  FP_mean=mean(FP),FN_mean=mean(FN),predictions_mean=mean(predictions),
  micro_precision=sum(TP)/(sum(TP)+sum(FP)),micro_recall=sum(TP)/(sum(TP)+sum(FN)),
  .groups="drop")
write.csv(df,file.path(root,"per_dataset.csv"),row.names=FALSE)
write.csv(summary,file.path(root,"summary.csv"),row.names=FALSE)

# Fixed-method CV: threshold learned from training folds only. Test levels
# remain label-selected to mirror the paper, and are labelled as such.
base=readRDS("upstream/scoth-segmentation/output-data/summarizing_results_F1/summary.RDS") %>%
  filter(groundtruth_name=="groundtruth",cost_method=="reg_cusum_L2") %>%
  transmute(dataset=dataset_name,method="Original",threshold=selection_threshold_included,
            level=selection_level,F1)
new=bind_rows(lapply(list.files("results/latest_r/cases",pattern="@Delayed3\\.csv$",full.names=TRUE),read.csv)) %>%
  transmute(dataset,method="Delayed3",threshold,level,F1)
all=bind_rows(base,new) %>% left_join(split[,c("dataset","family","fold")],by="dataset")
cv=list(); choices=list()
for (method in c("Original","Delayed3")) for (rule in c("OracleLevel","FixedLevel")) for (fold in 0:4) {
  rows=all %>% filter(.data$method==.env$method)
  if (rule=="OracleLevel") {
    rows=rows %>% group_by(dataset,threshold) %>%
      arrange(desc(F1),level,.by_group=TRUE) %>% slice(1) %>% ungroup()
    train=rows %>% filter(.data$fold!=.env$fold) %>% group_by(threshold) %>%
      summarize(F1=mean(F1),.groups="drop") %>% arrange(desc(F1),desc(threshold)) %>% slice(1)
  } else {
    train=rows %>% filter(.data$fold!=.env$fold) %>% group_by(threshold,level) %>%
      summarize(F1=mean(F1),.groups="drop") %>% arrange(desc(F1),level,desc(threshold)) %>% slice(1)
  }
  test=rows %>% filter(.data$fold==.env$fold,threshold==train$threshold[1])
  if (rule=="FixedLevel") test=filter(test,level==train$level[1])
  test$rule=rule
  cv[[length(cv)+1]]=test
  train$method=method;train$test_fold=fold;train$rule=rule;choices[[length(choices)+1]]=train
}
cv=bind_rows(cv)
write.csv(cv,file.path(root,"fixed_method_cv_by_dataset.csv"),row.names=FALSE)
write.csv(cv %>% group_by(method,rule) %>% summarize(datasets=n(),F1_mean=mean(F1),F1_sd=sd(F1),.groups="drop"),
          file.path(root,"fixed_method_cv_summary.csv"),row.names=FALSE)
write.csv(bind_rows(choices),file.path(root,"fixed_method_cv_settings.csv"),row.names=FALSE)

# Equal-size model families for oracle comparison: keep original mean cost,
# replace only the linear branch in the new family.
mean_scores=readRDS("upstream/scoth-segmentation/output-data/summarizing_results_F1/summary.RDS") %>%
  filter(groundtruth_name=="groundtruth",cost_method=="cusum_L2") %>%
  transmute(dataset=dataset_name,method="Mean",threshold=selection_threshold_included,level=selection_level,F1)
oracle=list()
for (method in c("Original","Delayed3")) {
  current=bind_rows(filter(all,.data$method==.env$method) %>% select(dataset,method,threshold,level,F1),mean_scores)
  best=current %>% group_by(dataset) %>% arrange(desc(F1),.by_group=TRUE) %>% slice(1) %>% ungroup()
  oracle[[method]]=data.frame(pipeline=method,datasets=nrow(best),F1_mean=mean(best$F1),F1_sd=sd(best$F1))
}
write.csv(bind_rows(oracle),file.path(root,"family_oracle_summary.csv"),row.names=FALSE)

joined=inner_join(filter(df,pipeline=="Original"),filter(df,pipeline=="Delayed3"),by="dataset",suffix=c("_old","_new")) %>%
  left_join(split[,c("dataset","family")],by="dataset")
joined$delta=joined$F1_new-joined$F1_old
set.seed(31081)
groups=base::split(joined$delta,joined$family)
ci=quantile(replicate(5000,mean(unlist(groups[sample(seq_along(groups),length(groups),replace=TRUE)],use.names=FALSE))),c(.025,.975))
write.csv(data.frame(mean_delta=mean(joined$delta),ci95_lower=ci[1],ci95_upper=ci[2],
  wins=sum(joined$delta>1e-10),ties=sum(abs(joined$delta)<=1e-10),losses=sum(joined$delta< -1e-10)),
  file.path(root,"paired_difference.csv"),row.names=FALSE)
write.csv(joined %>% select(dataset,family,F1_old,F1_new,delta,FP_old,FP_new,FN_old,FN_new),
  file.path(root,"paired_by_dataset.csv"),row.names=FALSE)
capture.output(sessionInfo(),file=file.path(root,"sessionInfo.txt"))
write_json(list(original=list(cost="linear",threshold=.1),latest=list(method="Delayed3",threshold=.09,
  repair_k=4,min_distance=3,release_level=3),datasets=42,
  secondary_metrics="F1-biased/covering use SAME predictions selected by primary F1; not separately oracle-optimized",
  timing="Matched timing: timing_summary.csv; three repeats per dataset, median; preparation + scoring + 10-level selection; no saved-score/cost reuse",
  caveat="Exploratory previously inspected benchmark; primary and fixed-method CV use label-selected test levels"),
  file.path(root,"metadata.json"),pretty=TRUE,auto_unbox=TRUE)
print(summary);print(bind_rows(oracle))
cat("AUTHOR_VS_LATEST_COMPARISON_FINISHED\n")
