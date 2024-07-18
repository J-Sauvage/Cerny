# DATES

DATES was run on dataset 1 (see Materials and Methods section of the paper)

## Run DATES

### Paris Basin Early Neolithic
```bash
dates -p parfile_DATES_4M2v2_metiss_WHG_AnatoliaEN_BPEN_20240228.txt > DATES_4M2v2_metiss_WHG_AnatoliaEN_BPEN_20240228.log
```

parfile:
```txt
genotypename: Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_20240109.geno
snpname: Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_20240109.snp
indivname: Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_modifWHG_20240109.ind
admixlist: admixlist_DATES_4M2v2_metiss_WHG_AnatoliaEN_BPEN_20240228.txt
maxdis: 1.0
seed: 77
jackknife: YES
qbin: 10
runfit: YES
afffit: YES
lovalfit:  0.45
checkmap: NO
```

admixlist:
```txt
WHG Turkey_N France_BassinParisien_EN metiss_WHG_AnatoliaEN_BPEN_4M2v2_20240228
```


### Cerny

```bash
dates -p parfile_DATES_4M2v2_metiss_WHG_AnatoliaEN_Cerny_20240228.txt > DATES_4M2v2_metiss_WHG_AnatoliaEN_Cerny_20240228.log
```

parfile:
```txt
genotypename: Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_20240109.geno
snpname: Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_20240109.snp
indivname: Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_modifWHG_20240109.ind
admixlist: admixlist_DATES_4M2v2_metiss_WHG_AnatoliaEN_Cerny_20240228.txt
maxdis: 1.0
seed: 77
jackknife: YES
qbin: 10
runfit: YES
afffit: YES
lovalfit:  0.45
checkmap: NO
```

admixlist:
```txt
WHG Turkey_N France_BassinParisien_MN_Cerny metiss_WHG_AnatoliaEN_Cerny_4M2v2_20240228
```


### Fleury

```bash
dates -p parfile_DATES_4M2v2_metiss_WHG_AnatoliaEN_Fleury_20240228.txt > DATES_4M2v2_metiss_WHG_AnatoliaEN_Fleury_20240228.log
```

parfile:
```txt
genotypename: Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_20240109.geno
snpname: Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_20240109.snp
indivname: Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_modifWHG_20240109.ind
admixlist: admixlist_DATES_4M2v2_metiss_WHG_AnatoliaEN_Fleury_20240228.txt
maxdis: 1.0
seed: 77
jackknife: YES
qbin: 10
runfit: YES
afffit: YES
lovalfit:  0.45
checkmap: NO
```

admixlist:
```txt
WHG Turkey_N France_Fleury_MN metiss_WHG_AnatoliaEN_Fleury_4M2v2_20240228
```


### Gurgy

```bash
dates -p parfile_DATES_4M2v2_metiss_WHG_AnatoliaEN_Gurgy_20240228.txt > DATES_4M2v2_metiss_WHG_AnatoliaEN_Gurgy_20240228.log
```

parfile:
```txt
genotypename: Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_20240109.geno
snpname: Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_20240109.snp
indivname: Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_modifWHG_20240109.ind
admixlist: admixlist_DATES_4M2v2_metiss_WHG_AnatoliaEN_Gurgy_20240228.txt
maxdis: 1.0
seed: 77
jackknife: YES
qbin: 10
runfit: YES
afffit: YES
lovalfit:  0.45
checkmap: NO
```

admixlist:
```txt
WHG Turkey_N France_Gurgy_MN metiss_WHG_AnatoliaEN_Gurgy_4M2v2_20240228
```


## Plot

```R
data = read.table("DatesC14_metissage_WHG_AnatoliaEN_20240228.csv", dec = ".", sep = "\t", header = T, na.strings = NA)

# Define the order of pops
custom_order <- c("France_ParisBasin_Gurgy_MN", "France_Normandy_Fleury_MN", "France_ParisBasin_MN_Cerny", "France_ParisBasin_EN")

# Convert Pop to a factor with custom order
data$Pop <- factor(data$Pop, levels = custom_order)

pdf("plot_DatesC14_metissage_WHG_AnatoliaEN_20240228.pdf", height = 3)

ggplot(data, aes(x = Moyenne, y = Pop)) + 
  geom_pointrange(aes(xmin=Date_C14_inf, xmax=Date_C14_sup), color = "black", shape = 15, size = 3, fatten = 0.5) + 
  geom_point(aes(x = Metissage, y = Pop), color = "black", shape = 16) +
  geom_pointrange(aes(xmin = Metissage-std.error, xmax = Metissage+std.error)) +
  scale_x_continuous(name = "Years cal BC", breaks = scales::pretty_breaks(n = 10)) + 
  scale_y_discrete(name = element_blank()) + 
  theme_bw() +
  geom_rect(aes(xmin = -5100, xmax = -4800, ymin = 3.9, ymax = 4.1)) +
  geom_rect(aes(xmin = -4901, xmax = -3980, ymin = 2.9, ymax = 3.1)) +
  geom_rect(aes(xmin = -4678, xmax = -3958, ymin = 1.9, ymax = 2.1)) +
  geom_rect(aes(xmin = -4750, xmax = -4550, ymin = 0.9, ymax = 1.1))

dev.off()
```
