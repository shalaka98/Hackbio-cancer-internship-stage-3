<h2 align="center">  Identification of Smoking-Associated Biomarkers in Stage I Lung Adenocarcinoma through Transcriptomic Profiling and Machine Learning </h2>

> raw data: https://portal.gdc.cancer.gov/analysis_page?app=Downloads 

## Introduction
Lung cancer is one of the most common carcinomas in the world and ranks first both in incidence and in mortality (Bray et al., 2024).  Lung adenocarcinoma (LUAD) is the most common subtype of non-small cell lung cancer (NSCLC), and NSCLC accounts for approximately 85% of all lung cancer cases(Gridelli et al., 2015). Smoking is its strongest risk factor and there is a significant and positive correlation between cigarette smoke and lung cancer(Hecht, 1999).
In this study, we aimed to identify potential smoking-associated biomarkers of stage 1 lung Adenocarcinoma based on smoking habits using transcriptomic data and machine learning models. 

## Materials and Methods:
Transcriptome profiling data for lung adenocarcinoma was obtained from the TCGA-LUAD dataset, including 40 samples (20 irregular and 20 regular smokers) of white individuals with stage 1 tumors. Low-expression genes were filtered out. Differential expression analysis between irregular and regular smokers was performed using TCGAbiolinks in R, with criteria of Fdr ≤ 0.01 and logFC ≥ 2. Results were visualized with heatmaps and volcano plots, and enrichment analysis was conducted after mapping ensembl IDs to gene IDs.

![Volcano Plot with Colored Points](Images/Volcano Plot with Colored Points.png)
<p align="center"> Fig 1: Volcano Plot with Colored Points </p>

ML analysis aimed to identify smoking-associated biomarkers in lung adenocarcinoma. After cleaning and transposing the RNA-seq data, feature selection was done via variance thresholding. The dataset was split into training and test sets, and a Random Forest classifier was tuned using GridSearchCV. Model performance was evaluated with metrics like the confusion matrix, classification report, and ROC-AUC curve. The top 10 important genes were identified, suggesting potential smoking-related biomarkers.

## Results
Gene expression profiles from TCGA-LUAD were used to compare Regular and Irregular Smokers. RNAseq data revealed several DEGs. The volcano plot showed distinct clustering of Regular and Irregular Smokers. Out of 33,439 genes, 741 were upregulated, and 2,313 were downregulated, and enrichment analysis highlighted gene regulation, transcription, and metabolic homeostasis processes. 



The ML model was evaluated using a confusion matrix, classification report, accuracy, and ROC curve. It predicted 3 true positives, 4 true negatives, 1 false positive, and 1 false negative, with an overall accuracy of 87.5%. Precision was 100% for irregular smokers and 75% for regular smokers, while the F1-scores were 0.89 and 0.86, respectively. The ROC AUC was 0.93, indicating strong classification performance.

![Confusion Matrix_ml](Images/Confusion Matrix_ml.png)
<p align="center">Fig 1: Confusion Matrix </p>

![ROC Curve_Ml](Images/ROC Curve_Ml.png)
<p align="center">Fig 1: ROC Curve_Ml </p>

![Top 10 genes in predicting smoking habit from samples_ml](Images/Top 10 genes in predicting smoking habit from samples_ml.png)
<p align="center">Fig 1: Top 10 genes in predicting smoking habit from samples_ml </p>


## Conclusion
This study explored smoking-associated biomarkers in stage I lung adenocarcinoma using transcriptomic profiling and machine learning. We identified 741 upregulated and 2,313 downregulated genes, with enrichment analysis highlighting key pathways like MODY signaling and melatonin degradation. The machine learning model achieved 87.5% accuracy in distinguishing regular and irregular smokers, identifying RGS1, RAB3B, and LINC01551 as top biomarkers. Previous research links Rab3B (Yao et al., 2024) and RGS1 (Wang et al., 2023) to lung adenocarcinoma aggressiveness and prognosis. These findings offer potential biomarkers for early diagnosis, prognosis, and targeted therapy in smoking-related lung cancer, warranting further validation in larger cohorts.


