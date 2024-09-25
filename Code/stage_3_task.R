#BiocManager::install("TCGAbiolinks")
#BiocManager::install("edgeR")
#BiocManager::install("limma")
#BiocManager::install("EDASeq")
library("TCGAbiolinks")
library(SummarizedExperiment)
library(biomaRt)
library("limma")
library("edgeR")
library("EDASeq")
library(gplots)

#getProjectSummary("TCGA-LUAD")

#Download and preprocess data
lung_acarcinoma <- GDCquery(project = "TCGA-LUAD",
                data.category = "Transcriptome Profiling",
                data.type = "Gene Expression Quantification")
GDCdownload(lung_acarcinoma)
lung.data <- GDCprepare(lung_acarcinoma)
head(lung.data)

# Explore Some Metadata Information
lung.data$definition
lung.data$cigarettes_per_day
lung.data$race
count(lung.data$ajcc_pathologic_stage=="Stage IIIA", na.rm=T)

#creating metadata table
slotNames(lung.data)
all_meta <- data.frame(a=lung.data$paper_expression_subtype)

lung_acarcinoma_meta <- data.frame("barcode"=lung.data$barcode,
                                   "sample_type"=lung.data$definition,
                         "cigarettes_per_day"=lung.data$cigarettes_per_day,
                         "race"=lung.data$race,
                         "pathologic_stage"=lung.data$ajcc_pathologic_stage)
head(lung_acarcinoma_meta)

#filtering metadata for NA containing records
NA_filtered_data <- na.omit(lung_acarcinoma_meta)
head(NA_filtered_data)

#select unstranded dataset
luad.raw.data <- assays(lung.data) #help to extract information summarizing the experiment
View(luad.raw.data$unstranded)

#extracting 20 irregular and 20 regular smoker data from white people having stage I tumor
selectedBarcodes <- c(subset(NA_filtered_data, race == "white" & pathologic_stage %in% c("Stage IA", "Stage IB") & sample_type == "Primary solid Tumor" & cigarettes_per_day < 1)$barcode[c(1:20)], subset(NA_filtered_data, race == "white" & pathologic_stage %in% c("Stage IA", "Stage IB") & sample_type == "Primary solid Tumor" & cigarettes_per_day > 3)$barcode[c(1:20)])
selectedData <- luad.raw.data$unstranded[,c(selectedBarcodes)]
View(selectedData)

# Data normalization and filtering
normData <- TCGAanalyze_Normalization(tabDF = selectedData, geneInfo = geneInfoHT, method = "geneLength")

# filtering the genes with lowest expression
filtData <- TCGAanalyze_Filtering(tabDF = normData,
                                  method = "quantile",
                                  qnt.cut = 0.25)

# Annotate first 20 columns as 'irregular_smoker'
colnames(filtData)[1:20] <- paste0("irregular_smoker_", 1:20)

# Annotate the last 20 columns as 'regular_smoker'
colnames(filtData)[21:40] <- paste0("regular_smoker_", 1:20)

#saving the normalized count data table as csv file where first 20 columns are for irregular smoker (<1 cigarette per day) and the last 20 columns are for regular smoker (>2 cigarettes per day) 
write.csv(filtData, file = "Normalized_count_Data_final.csv", row.names = TRUE)

#filtData <- read.csv("/home/hp/Documents/Stage_3_task/Normalized_count_Data_final.csv", row.names = 1)
View(filtData)

#Differential Expression Analysis
selectResults <- TCGAanalyze_DEA(
  mat1 = filtData[, grep("^irregular_smoker_", colnames(filtData))],  # Selecting the 'irregular_smoker' columns
  mat2 = filtData[, grep("^regular_smoker_", colnames(filtData))],    # Selecting the 'regular_smoker' columns
  Cond1type = "Irregular Smoker",
  Cond2type = "Regular Smoker",
  pipeline = "edgeR",
  fdr.cut = 0.01,
  logFC.cut = 2
)
dim(selectResults)
selectResults.level <- TCGAanalyze_LevelTab(selectResults,"Irregular Smoker", "Regular Smoker",
                                            filtData[,grep("^irregular_smoker_", colnames(filtData))],
                                            filtData[,grep("^regular_smoker_", colnames(filtData))])
View(selectResults.level)
#heatmap
heat.data <- filtData[rownames(selectResults.level),]
#color the plot by the type of smoking status
smoking.status <- c(rep("Irregular",20), rep("Regular",20))
color_codes <- c()
for (i in smoking.status){
  if (i == "Irregular"){
    color_codes <- c(color_codes, "red")
  }else{
    color_codes <- c(color_codes, "blue")
  }
}

# Now plot the heatmap
heatmap.2(x=as.matrix(heat.data),
          col=hcl.colors(10, palette = "Viridis"),
          Rowv = F, Colv = T,
          scale = "row",
          sepcolor = "black",
          trace = "none",
          key = TRUE,
          dendrogram = "col",
          cexRow = 0.4, cexCol = 0.8,
          main = "Heatmap of DEGs by Smoking Status",
          na.color = "black",
          srtCol = 45,
          ColSideColors = color_codes)

#Enrichment analysis
#View the volcano plot first
# Sample plot: x-axis (logFC), y-axis (-log10(FDR))
plot(x = selectResults.level$logFC, 
     y = -log10(selectResults.level$FDR),
     col = ifelse(selectResults.level$logFC > 0, "blue", "red"),  # Blue for positive, red for negative
     pch = 16,  # Set point shape (optional)
     xlab = "logFC", 
     ylab = "-log10(FDR)",
     main = "Volcano Plot with Colored Points")  # Title of the plot
upreg.genes <- rownames(subset(selectResults.level, logFC > 2))
downreg.genes <- rownames(subset(selectResults.level, logFC < -2))

#convert ensembl IDs to gene IDs using biomart
mart <- useMart(biomart = "ensembl", dataset = "hsapiens_gene_ensembl")
upreg.genes <- getBM(attributes = c("ensembl_gene_id",'hgnc_symbol'),
                     filters = "ensembl_gene_id",
                     values = upreg.genes,
                     mart = mart)$hgnc_symbol
downreg.genes <- getBM(attributes = c("ensembl_gene_id",'hgnc_symbol'),
                     filters = "ensembl_gene_id",
                     values = downreg.genes,
                     mart = mart)$hgnc_symbol

#enrichment analysis for both
up.EA <- TCGAanalyze_EAcomplete(TFname="Upregulated",upreg.genes)
down.EA <- TCGAanalyze_EAcomplete(TFname="Downregulated",downreg.genes)
TCGAvisualize_EAbarplot(tf = rownames(up.EA$ResBP),
                        GOBPTab = up.EA$ResBP,
                        GOCCTab = up.EA$ResCC,
                        GOMFTab = up.EA$ResMF,
                        PathTab = up.EA$ResPat,
                        nRGTab = upreg.genes,
                        nBar = 5,
                        text.size = 2,
                        fig.width = 30,
                        fig.height = 15)
TCGAvisualize_EAbarplot(tf = rownames(down.EA$ResBP),
                        GOBPTab = down.EA$ResBP,
                        GOCCTab = down.EA$ResCC,
                        GOMFTab = down.EA$ResMF,
                        PathTab = down.EA$ResPat,
                        nRGTab = downreg.genes,
                        nBar = 5,
                        text.size = 2,
                        fig.width = 30,
                        fig.height = 15)
