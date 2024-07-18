# qpAdm

qpAdm was run on dataset 1 (see Materials and Methods section of the paper).

## Populations

Targets
```txt
BAL20A
BAL28
GLS101
MARC1
MART97
BAL6
BAL19
BAL31B
BAL33
BAL35
BAL45
BAL48
BAL52C
GLS352
GLS356-1
GLS356-2
OLF17
VPB72-1
VPB72-2
VPB148A
VPB148C
VPB180
VPB192
VPB245
VPB257
VPB274
France_Fleury_MN
France_Gurgy_MN
```

Sources
```txt
Turkey_N
WHG
```

Outgroups (rightfile)
```txt
Mbuti
PapuanHighlands
Han
Karitiana
Ethiopia_4500BP
Russia_Ust_Ishim_HG
Russia_MA1_HG
Czech_Vestonice16
Israel_Natufian
Georgia_Kotias
Belgium_GoyetQ116-1
```


## Préparation des leftfiles

```bash
cat Samples.txt | while read sample
do
echo "$sample" >> leftfile.$sample.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240212.txt
echo "Turkey_N" >> leftfile.$sample.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240212.txt
echo "WHG" >> leftfile.$sample.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240212.txt
done
```

Samples.txt:
```txt
BAL20A
BAL28
GLS101
MARC1
MART97
BAL6
BAL19
BAL31B
BAL33
BAL35
BAL45
BAL48
BAL52C
GLS352
GLS356-1
GLS356-2
OLF17
VPB72-1
VPB72-2
VPB148A
VPB148C
VPB180
VPB192
VPB245
VPB257
VPB274
France_Fleury_MN
France_Gurgy_MN
```


## Préparation des parfiles

```bash
cat Samples.txt | while read sample
do

echo "genotypename: /home/juliette/Documents/Genet_des_Pop/Fichiers_eigenstat/Merge_Panel_NeoAncien_NeoMoyen/4M2_1000G_v2_20240109/Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_20240109.geno" >> parfile.$sample.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240212.txt
echo "snpname: /home/juliette/Documents/Genet_des_Pop/Fichiers_eigenstat/Merge_Panel_NeoAncien_NeoMoyen/4M2_1000G_v2_20240109/Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_20240109.snp" >> parfile.$sample.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240212.txt
echo "indivname: /home/juliette/Documents/Genet_des_Pop/Fichiers_eigenstat/Merge_Panel_NeoAncien_NeoMoyen/4M2_1000G_v2_20240109/Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_modifWHG_CernyInd_20240109.ind" >> parfile.$sample.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240212.txt
echo "popleft: leftfile.$sample.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240212.txt" >> parfile.$sample.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240212.txt
echo "popright: rightfile_AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240212.txt" >> parfile.$sample.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240212.txt
echo "details: YES" >> parfile.$sample.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240212.txt
echo "allsnps: YES" >> parfile.$sample.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240212.txt
echo "inbreed: NO" >> parfile.$sample.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240212.txt

done
```


## Run qpAdm

```bash
cat Samples.txt | while read sample
do

qpAdm -p parfile.$sample.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240212.txt > resultats.$sample.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240212.txt

done
```


## Plot

```R
data = read.csv("resultats.formate.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240322.csv", header = T, sep = "\t", dec = ".", na.strings = "NA")

# Define the order of samples
custom_order <- c("Gurgy", "Fleury", "VPB274", "VPB257", "VPB245", "VPB180", "VPB148C", "VPB148A", "VPB72-2", "GLS356-2", "GLS352", "BAL52C", "BAL48", "BAL45", "BAL33", "BAL31B", "BAL6", "GLS101", "BAL28", "BAL20A")

# Convert Sample to a factor with custom order
data$Sample <- factor(data$Sample, levels = custom_order)

pdf("plot.AncestryProportion_AnatoliaEN_WHG_inBassinParisienInd_20240322.pdf")

ggplot(data, aes(x=Sample, y=Proportion, fill=Ancestry)) +
  geom_bar(stat="identity") + 
  geom_errorbar( aes(x=Sample, ymin=Proportion-std.err, ymax=Proportion+std.err), width=0.3, colour="black", alpha=0.9, size=0.5) +
  scale_fill_manual(name="", values=c("WHG" = "#398b9c", "Anatolia_EN" = "#8c0505"), breaks=c("Anatolia_EN", "WHG"), labels=c("AnatoliaEN", "WHG")) + 
  coord_flip() +
  theme_bw() +
  theme(panel.border = element_blank()) +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  labs(y="Ancestry proportion") + 
  theme(axis.title.y = element_blank())

dev.off()
```


