## add annotation to results tables with gene names and locations.
## Combine all results tables into a single .rds object
## extract table of Number of significant up/down regulated genes by different thresholds

## some special considerations for repeat families:
## If you are going to just look at family level alignment you can use star and randomly
## assign a multimapping read to a single locus
## If you want to get per locus information, it is better to use salmon pseudo alignment
## as it assigns multimappers based on EM from other reads.

library(GenomicRanges)
library(rtracklayer)
library(ggplot2)
library(dplyr)
library(BSgenome.Celegans.UCSC.ce11)
library(ggpubr)
library(plotly)
library(ggrepel)
library(rstatix)
library(htmlwidgets)
library(RColorBrewer)
library(ComplexHeatmap)
library(DESeq2)


theme_set(
  theme_classic()+
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          axis.title.y=ggtext::element_markdown(size=9),
          axis.title.x=ggtext::element_markdown(size=9),
          title=ggtext::element_markdown(size=9)
    )
)

options(width=10000)

serverPath="/Volumes/external.data/MeisterLab"
#serverPath="Z:/MeisterLab"
workDir=paste0(serverPath,"/FischleLab_KarthikEswara/ribo0seq_squire")
runName="/repeats"
prefix=""

setwd(workDir)
dir.create(paste0(workDir,runName,"/custom/rds"), showWarnings = FALSE, recursive = TRUE)
dir.create(paste0(workDir,runName,"/custom/txt"), showWarnings = FALSE, recursive = TRUE)
genomeVer<-"ce11"

### functions ------
annotate_rpt_results <- function(inpath,outpath){
  namesList<-list.dirs(inpath,full.names=F,recursive=F)
  #group_name=namesList[1]
  for(group_name in namesList){
    print(group_name)

    # extract repeat family stats
    rpts <- read.delim(paste0(inpath,"/",group_name,"/DESeq2_TE_only.txt"), header=T)
    md<-strsplit(rownames(rpts),"\\|")

    rpts$chr<-sapply(md,"[[",1)
    rpts$start<-sapply(md,"[[",2)
    rpts$end<-sapply(md,"[[",3)
    rpts$strand<-sapply(strsplit(sapply(md,"[[",6),","),"[[",1)
    rpts$otherStrand<-sapply(strsplit(sapply(md,"[[",6),","),"[[",2)
    rpts$gene_id<-sapply(strsplit(sapply(md,"[[",4),":"),"[[",1)
    rpts$family_id<-sapply(strsplit(sapply(md,"[[",4),":"),"[[",2)
    rpts$class_id<-sapply(strsplit(sapply(md,"[[",4),":"),"[[",3)
    rpts$group<-group_name

    # get table with score
    score <- read.delim(paste0(inpath,"/",group_name,"/",group_name,"_TE_combo.txt"), header=T)
    rpts$names_long<-sapply(strsplit(rownames(rpts),","),"[[",1)
    idx<-match(rpts$names_long,score$TE_ID)
    rpts$score=score$score[idx]
    rownames(rpts)<-NULL
    dir.create(outpath,showWarnings=F,recursive=T)
    write.table(rpts, paste0(outpath,"/rpts_",group_name,
                             ".deseq2.results_annotated.tsv"),
                row.names=F, quote=F, sep="\t", col.names=T)
  }
}


combine_rpt_results <- function(pattern="\\.deseq2\\.results_annotated\\.tsv",inpath){
  fileList <- list.files(paste0(inpath,"/txt"), pattern=pattern, full.names=T)
  results <- do.call(rbind, lapply(fileList, read.delim, header=T))
  return(results)
}


## annotate results tables -----

contrasts<-read.csv(paste0(workDir,"/contrasts.csv"),sep=",",header=T)
samplesheet<-read.csv(paste0(workDir,"/samplesheet.csv"),sep=",",header=T)
annotate_rpt_results(inpath=paste0(workDir,"/squire_call"),outpath=paste0(workDir,runName,"/txt"))

results<-combine_rpt_results(inpath=paste0(workDir,runName),pattern="\\.deseq2\\.results_annotated\\.tsv")
dir.create(paste0(workDir,runName,"/rds"),showWarnings=F,recursive=T)
saveRDS(results, paste0(workDir,runName,"/rds/rpts_",prefix,".results_annotated.RDS"))


results<-readRDS(paste0(workDir,runName,"/rds/rpts_",prefix,".results_annotated.RDS"))


# Collect counts for DESeq2 family analysis
namesList<-list.dirs(paste0(workDir,"/squire_call"),full.names=F,recursive=F)
group_name=namesList[2]
allcnts<-NULL
for(group_name in namesList){
  print(group_name)
  # extract repeat family counts
  cnts <- read.delim(paste0(workDir,"/squire_call/",group_name,"/",group_name,"_gene_TE_counttable.txt"), header=T)
  if(is.null(allcnts)){
    allcnts<-cnts
  } else {
    idx<-colnames(cnts) %in% colnames(allcnts)
    idx[1]<-FALSE # keep gene_id for merging
    if(sum(!idx)>1){ # make sure there are columns to merge
      allcnts<-left_join(allcnts,cnts[,!idx],by="gene_id")
    }
  }
  # # summarise by families
  # rptidx<-grepl("^chr",cnts$gene_id)
  # genecnts<-cnts[!rptidx,]
  # rptcnts<-cnts[rptidx,]
  # md<-strsplit(rptcnts$gene_id,"\\|")
  # rptcnts$subfamily_id<-sapply(strsplit(sapply(md,"[[",4),":"),"[[",1)
  # #family_id<-sapply(strsplit(sapply(md,"[[",4),":"),"[[",2)
  # #class_id<-sapply(strsplit(sapply(md,"[[",4),":"),"[[",3)
  # rptcnts$gene_id<-NULL
  # rptcnts<-rptcnts %>% as.data.frame() %>% group_by(subfamily_id) %>%
  #   summarise(across(everything(),sum,na.rm=T)) %>% as.data.frame()
}

# merge repeats by families
rptidx<-grepl("^chr",allcnts$gene_id)
genecnts<-allcnts[!rptidx,]
rptcnts<-allcnts[rptidx,]
md<-strsplit(rptcnts$gene_id,"\\|")
rptcnts$subfamily_id<-sapply(strsplit(sapply(md,"[[",4),":"),"[[",1)

rptcnts$gene_id<-NULL
rptcnts<-rptcnts %>% as.data.frame() %>% group_by(subfamily_id) %>%
  summarise(across(everything(),\(x) sum(x,na.rm=T)),count=n()) %>% as.data.frame()
rownames(rptcnts)<-rptcnts$subfamily_id
head(rptcnts)
contrasts


# do DESeq2 on repeat families
results<-NULL

for(i in 1:nrow(contrasts)){
  contrast<-contrasts$id[i]
  if(contrast %in% c("lin61_vs_N2","lin61_vs_HPL2GFP__lin61")){
    next()
  }
  print(contrast)
  ctrl<-contrasts$reference[i]
  treat<-contrasts$target[i]
  ctrls<-samplesheet$sample[grepl(paste0("^",ctrl,"$"),samplesheet$phenotype)]
  treats<-unique(samplesheet$sample[grepl(paste0("^",treat,"$"),samplesheet$phenotype)])
  tmpss<-samplesheet[samplesheet$phenotype %in% c(ctrl,treat),]
  tmpss<-tmpss[!duplicated(tmpss$sample),]

  dds<-DESeqDataSetFromMatrix(countData=rptcnts[,colnames(rptcnts) %in% tmpss$sample],
                              colData=tmpss,
                              design=~replicate+phenotype)
  dds <- DESeq(dds)
  resultsNames(dds)
  res <- lfcShrink(dds, contrast=c("phenotype",treat,ctrl),type="ashr")
  res$group<-contrast
  res$gene_id<-rownames(res)
  res$famSize<-rptcnts$count
  if(is.null(results)){
    results<-res
  } else {
    results<-rbind(results,res)
  }
}

dir.create(paste0(workDir,"/repeatFamilies/rds"),showWarnings=F,recursive=T)
saveRDS(results,paste0(workDir,"/repeatFamilies/rds/allResults.rds"))
