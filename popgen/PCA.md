# PCA

PCA was run on dataset 2 (see Materials and Methods section of the paper).

## Run smartpca

```bash
/usr/lib/eigensoft/smartpca -p parfile_smartpca_PapierCerny_4M2v2_20240115.txt
```
parfile:
```txt
genotypename: /home/juliette/Documents/Genet_des_Pop/Fichiers_eigenstat/Merge_Panel_NeoAncien_NeoMoyen/4M2_1000G_v2_20240109/Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_LDpruned_20240109.geno
snpname: /home/juliette/Documents/Genet_des_Pop/Fichiers_eigenstat/Merge_Panel_NeoAncien_NeoMoyen/4M2_1000G_v2_20240109/Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_LDpruned_20240109.snp
indivname: /home/juliette/Documents/Genet_des_Pop/Fichiers_eigenstat/Merge_Panel_NeoAncien_NeoMoyen/4M2_1000G_v2_20240109/Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_LDpruned_20240109.ind
evecoutname: ACP_Panel4M2v2_BassinParisien_NeoAncien_NeoMoyen_20240115.evec
evaloutname: ACP_Panel4M2v2_BassinParisien_NeoAncien_NeoMoyen_20240115.eval
numoutlieriter: 0
poplistname: ACP_PapierCerny_4M2v2_popmodernlist_20240115.txt
lsqproject: YES
numoutevec: 6
numthreads: 1
```

popmodernlist:
```txt
Adygei
Basque
BergamoItalian
CEU
FIN
French
GBR
IBS
Orcadian
Russian
Sardinian
TSI
Tuscan
```

## Plot

```R
ACP = read.csv("ACP_Panel4M2v2_BassinParisien_NeoAncien_NeoMoyen_20240115.csv", header = T, sep = "\t", dec = ".", na.strings = "NA")

pdf("ACP_Panel4M2v2_BassinParisien_NeoAncien_NeoMoyen_20240115.pdf")

plot(ACP$PC1, ACP$PC2, xlab = "PC1 (4.7%)", ylab = "PC2 (2.1%)", xlim = c(-0.1, 0.1), ylim = c(-0.1, 0.1), cex = 0.7, col = (ACP$AncientColor = as.character(ACP$AncientColor)), pch = ACP$AncientPoint)
par(new = TRUE)
plot(ACP[which(ACP$AncientLabel=="Paris_basin"),]$PC1, ACP[which(ACP$AncientLabel=="Paris_basin"),]$PC2, xlab = "PC1 (4.7%)", ylab = "PC2 (2.1%)", xlim = c(-0.1, 0.1), ylim = c(-0.1, 0.1), cex = 0.9, col = (ACP[which(ACP$AncientLabel=="Paris_basin"),]$AncientColor = as.character(ACP[which(ACP$AncientLabel=="Paris_basin"),]$AncientColor)), pch = ACP[which(ACP$AncientLabel=="Paris_basin"),]$AncientPoint)
legend("bottomleft", box.lty = 0, bg = "white", cex = 0.7, ncol = 3, legend = c("Modern", NA, "Mesolithic Hunter-gatherers", "Eastern HG", "Scandinavian HG", "South-Eastern HG", "Western HG", "Farmers 7000 BCE – 5000 BCE", "Anatolia", "South-Eastern Europe", "Central Europe", "South-Western Europe", "France", "Paris basin", "Farmers 5000 BCE – 3000 BCE", "South-Eastern Europe", "Central Europe", "South-Western Europe", "British Isles", "France", "Paris basin Cerny"), col = c("#e4e4e4", NA, NA, "#9c8361", "#73479c", "#e5890d", "#398b9c", NA, "#8c0505", "#e5890d", "#fadf8f", "#c3ed64", "#a6cff4", "#0247ec", NA, "#e5890d", "#fadf8f", "#c3ed64", "#79b65e", "#a6cff4", "#0247ec"), pch = c(4, NA, NA, 17, 17, 17, 17, NA, 15, 15, 15, 15, 15, 15, NA, 16, 16, 16, 16, 16, 16))
par(new = TRUE)
par(plt = c(0.6, 0.94, 0.6, 0.882))
rect(0, 0, 1, 1, col = "white", border = NA)
par(new = TRUE)
plot(ACP$PC1, ACP$PC3, xlab = "PC1 (4.7%)", ylab = "PC3 (1.9%)", xlim = c(-0.14, 0.14), ylim = c(-0.14, 0.14), cex = 0.7, bg = "white", col = (ACP$AncientColor = as.character(ACP$AncientColor)), pch = ACP$AncientPoint)
par(new = TRUE)
plot(ACP[which(ACP$AncientLabel=="Paris_basin"),]$PC1, ACP[which(ACP$AncientLabel=="Paris_basin"),]$PC3, xlab = "PC1 (4.7%)", ylab = "PC3 (1.9%)", xlim = c(-0.14, 0.14), ylim = c(-0.14, 0.14), cex = 0.9, col = (ACP[which(ACP$AncientLabel=="Paris_basin"),]$AncientColor = as.character(ACP[which(ACP$AncientLabel=="Paris_basin"),]$AncientColor)), pch = ACP[which(ACP$AncientLabel=="Paris_basin"),]$AncientPoint)
par(new = FALSE)

dev.off()
```
