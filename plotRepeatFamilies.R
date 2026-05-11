library(GenomicRanges)
library(GenomeInfoDb)
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
library(cowplot)


theme_set(
  theme_classic()+
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          axis.title.y=ggtext::element_markdown(size=9),
          axis.title.x=ggtext::element_markdown(size=9),
          title=ggtext::element_markdown(size=9)
    )
)


serverPath="/Volumes/external.data/MeisterLab"
#serverPath="Z:/MeisterLab"

workDir=paste0(serverPath,"/FischleLab_KarthikEswara/ribo0seq_squire")
runName="/repeatFamilies"

contrasts<-read.csv(paste0(workDir,"/contrasts.csv"),sep=",",header=T)
prefix=""
#genomeVer="WS295"
setwd(workDir)

dir.create(paste0(workDir,runName,"/plots"))
# raw tpm

results<-readRDS(paste0(workDir,runName,"/rds/allResults.RDS"))

#sigFam<-unique(results$gene_id[results$count>=50 & results$padj<0.05])


# tpm<-read.delim(paste0(workDir,"/star_salmon/salmon.merged.gene_tpm.tsv"), header=T)
# #tpm<-read.delim(paste0(workDir,"/star_salmon/salmon.merged.gene_scaled.tsv"), header=T)
# dim(tpm)
# rpttpm<-tpm[!grepl("WBGene",tpm$gene_id),]
# rpttpm<-rpttpm[rpttpm$gene_id %in% sigFam,]
#
# mat_tpm<-as.matrix(log10(rpttpm[,!grepl("gene_",colnames(rpttpm))] + 1))
# row.names(mat_tpm)<-rpttpm$gene_id
#
# gtf<-import(paste0(serverPath,"/publicData/genomes/dfam35/",genomeVer,"_canonicalgenes_Dfam3.5nr_repeats.gtf"))
#
# familySize<-data.frame(gtf) %>% dplyr::filter(type=="gene",source=="Dfam_3.5") %>% group_by(gene_id) %>% summarise(count=n())
#
#
# png(paste0(workDir, runName,"/custom/plots/heatmaps/",prefix,"hclust_heatmap_rptFamilies_tpm.png"),
#     width=19,height=70,units="cm",res=150)
# plotTitle<-paste0("Log10(tpm) for all(",nrow(mat_tpm),") repeat families")
# ht<-Heatmap(mat_tpm,show_row_names=T, cluster_columns=F, cluster_rows=T,
#             show_row_dend = F,
#             column_names_rot=75, column_title=plotTitle,
#             col=circlize::colorRamp2(c(0,4),  c("white","darkblue")))
# ht<-draw(ht)
# dev.off()
#
# # normalise by family size
# idx<-match(row.names(mat_tpm),familySize$gene_id)
# if(all(familySize$gene_id[idx]==row.names(mat_tpm))){
#   norm_tpm<-mat_tpm/familySize$count[idx]
# } else {
#   print("could not match all ids!!!")
# }
#
# png(paste0(workDir, runName,"/custom/plots/heatmaps/",prefix,"hclust_heatmap_rptFamilies_tpm_norm.png"),
#     width=19,height=70,units="cm",res=150)
# plotTitle<-paste0("Log10(tpm) for all(",nrow(norm_tpm),") repeat families normalised by family size")
# ht<-Heatmap(norm_tpm,show_row_names=T, cluster_columns=F, cluster_rows=T,
#             show_row_dend = F,
#             column_names_rot=75, column_title=plotTitle,
#             col=circlize::colorRamp2(c(0,0.01,0.04,0.1),  c("white","lightblue","blue" ,"darkblue")))
# ht<-draw(ht)
# dev.off()


# log2fc ------
# results<-readRDS(paste0(workDir,runName,"/custom/rds/rptFam_.results_annotated.RDS"))
# results$group<-factor(results$group,levels=contrasts$shortId,
#                   labels=contrasts$id)
# results<-results[!grepl("rRNA",results$gene_id),]
# results<-results[results$gene_id %in% sigFam,]

results$group<-factor(results$group)
results$sig<-F
results$sig[results$padj<0.05]<-T
n2contrasts<-grep("vs_N2$",levels(results$group),value=T)
lin61contrasts<-grep("vs_HPL2GFP__lin61$",levels(results$group),value=T)

res_n2<-results[results$group %in% n2contrasts,]
res_lin61<-results[results$group %in% lin61contrasts,]

# n2 subset
pa<-ggplot(res_n2,aes(x=reorder(gene_id,-log2FoldChange),y=log2FoldChange,fill=sig)) +
  facet_grid(group~.,switch = "y")+
  geom_col() +
  geom_errorbar(
    aes(ymin = log2FoldChange - lfcSE, ymax = log2FoldChange + lfcSE),
    width = 0.2
  ) +
  geom_hline(yintercept=0,color="red")+
  theme(axis.text.x = element_text(angle = 90, hjust = 1),
        legend.position="none") +
  scale_fill_manual(values=c("grey40","blue"))
pa
pb<-ggplot(res_n2,aes(x=reorder(gene_id,-log2FoldChange),y=famSize)) +
  geom_col(fill="darkgreen")+
  theme(
    axis.text.x  = element_blank(),
    axis.title.x = element_blank()
  )
pb
pc<-ggplot(res_n2,aes(x=reorder(gene_id,-log2FoldChange),y=baseMean)) +
  geom_col(fill="purple")+
  theme(
    axis.text.x  = element_blank(),
    axis.title.x = element_blank()
  )
pc
p<-plot_grid(pb,pc,pa,ncol=1,align="v",rel_heights=c(1,1,10))
ggsave(paste0(workDir, runName,"/plots/",prefix,"results_n2_lfc_rptFamilies.png"),p,width=40,height=40,units="cm")


# lin-61 subset
pa<-ggplot(res_lin61,aes(x=reorder(gene_id,-log2FoldChange),y=log2FoldChange,fill=sig)) +
  facet_grid(group~.,switch = "y")+
  geom_col() +
  geom_errorbar(
    aes(ymin = log2FoldChange - lfcSE, ymax = log2FoldChange + lfcSE),
    width = 0.2
  ) +
  geom_hline(yintercept=0,color="red")+
  theme(axis.text.x = element_text(angle = 90, hjust = 1),
        legend.position="none") +
  scale_fill_manual(values=c("grey40","blue"))
pa
pb<-ggplot(res_lin61,aes(x=reorder(gene_id,-log2FoldChange),y=famSize)) +
  geom_col(fill="darkgreen")+
  theme(
    axis.text.x  = element_blank(),
    axis.title.x = element_blank()
  )
pb
pc<-ggplot(res_lin61,aes(x=reorder(gene_id,-log2FoldChange),y=baseMean)) +
  geom_col(fill="purple")+
  theme(
    axis.text.x  = element_blank(),
    axis.title.x = element_blank()
  )
pc
p<-plot_grid(pb,pc,pa,ncol=1,align="v",rel_heights=c(1,1,10))
p
ggsave(paste0(workDir, runName,"/plots/",prefix,"results_lin61_lfc_rptFamilies.png"),p,width=40,height=35,units="cm")

# lin61 subset reordered by hpl2
order_vec<-as.data.frame(res_lin61) %>% filter(group=="hpl2_vs_HPL2GFP__lin61") %>%
  arrange(log2FoldChange) %>% pull(gene_id)
df<-res_lin61
df$gene_id<-factor(df$gene_id,levels=order_vec)
df<-as.data.frame(df) %>% arrange(gene_id)

pa<-ggplot(df,aes(x=gene_id,y=log2FoldChange,fill=sig)) +
  facet_grid(group~.,switch = "y")+
  geom_col() +
  geom_errorbar(
    aes(ymin = log2FoldChange - lfcSE, ymax = log2FoldChange + lfcSE),
    width = 0.2
  ) +
  geom_hline(yintercept=0,color="red")+
  theme(axis.text.x = element_text(angle = 90, hjust = 1),
        legend.position="none") +
  scale_fill_manual(values=c("grey40","blue"))
pa
pb<-ggplot(df,aes(x=gene_id,y=famSize)) +
  geom_col(fill="darkgreen")+
  theme(
    axis.text.x  = element_blank(),
    axis.title.x = element_blank()
  )
pb
pc<-ggplot(df,aes(x=gene_id,y=baseMean)) +
  geom_col(fill="purple")+
  theme(
    axis.text.x  = element_blank(),
    axis.title.x = element_blank()
  )
pc
p<-plot_grid(pb,pc,pa,ncol=1,align="v",rel_heights=c(1,1,10))
ggsave(paste0(workDir, runName,"/plots/",prefix,"results_lin61_lfc_rptFamilies_hpl2mutOrder.png"),p,width=40,height=35,units="cm")


# order_vec<-as.data.frame(res_lin61) %>% filter(group=="lin61_vs_HPL2GFP__lin61") %>%
#   arrange(log2FoldChange) %>% pull(gene_id)
# df<-res_lin61
# df$gene_id<-factor(df$gene_id,levels=order_vec)
# df<-as.data.frame(df) %>% arrange(gene_id)
#
# pa<-ggplot(df,aes(x=gene_id,y=log2FoldChange,fill=sig)) +
#   facet_grid(group~.,switch = "y")+
#   geom_col() +
#   geom_errorbar(
#     aes(ymin = log2FoldChange - lfcSE, ymax = log2FoldChange + lfcSE),
#     width = 0.2
#   ) +
#   geom_hline(yintercept=0,color="red")+
#   theme(axis.text.x = element_text(angle = 90, hjust = 1),
#         legend.position="none") +
#   scale_fill_manual(values=c("grey40","blue"))
# pa
# pb<-ggplot(df,aes(x=gene_id,y=famSize)) +
#   geom_col(fill="darkgreen")+
#   theme(
#     axis.text.x  = element_blank(),
#     axis.title.x = element_blank()
#   )
# pb
# pc<-ggplot(df,aes(x=gene_id,y=baseMean)) +
#   geom_col(fill="purple")+
#   theme(
#     axis.text.x  = element_blank(),
#     axis.title.x = element_blank()
#   )
# pc
# p<-plot_grid(pb,pc,pa,ncol=1,align="v",rel_heights=c(1,1,10))
# ggsave(paste0(workDir, runName,"/custom/plots/heatmaps/",prefix,"results_lin61_lfc_rptFamilies_lin61mutOrder.png"),p,width=40,height=35,units="cm")
#
# sum(familySize$count>50)
#
