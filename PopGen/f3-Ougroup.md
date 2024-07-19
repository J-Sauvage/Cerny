# f3-Outgroup

f3-Outgroup was run on dataset 1 (see Materials and Methods section of the paper)

## Populations A, B and C

A
```txt
France_BassinParisien_MN_Cerny_Balloy
France_BassinParisien_MN_Cerny_Gron
France_BassinParisien_MN_Cerny_Orville
France_BassinParisien_MN_Cerny_Vignely
```

B
```txt
France_BassinParisien_EN
Austria_N_LBK
Bulgaria_N
Croatia_EN_Impressa
Croatia_N_Cardial
France_GrandEst_EN
France_HautsDeFrance_EN
France_Pendimoun_EN
Germany_EN_LBK
Gibraltar_EN
Greece_N
Hungary_EN_Starcevo
Hungary_MN_LBK
Italy_N
Serbia_IronGates_N
Spain_EN
Croatia_MN_Sopot
Czech_MN
France_Alsace_Lingolsheim_MN
France_ClosdeRoc_MN
France_DeuxSevres_MN
France_Fleury_MN
France_GrandEst_MN
France_Gurgy_MN
France_HautsDeFrance_MN
France_LesBreguieres_EN_MN
France_Obernai_MN
Hungary_LN_Lengyel
Italy_Sicily_MN
Serbia_EN
```

C
```txt
BEB
```

## Run Admixtools

```bash
qp3Pop -p parfile_f3out_Cerny_vs_WHG_Agri_CernySites_PapierCerny_4M2v2_20240123.txt > resultats_f3out_Cerny_vs_WHG_Agri_CernySites_PapierCerny_4M2v2_20240123.txt 
```

parfile
```txt
genotypename: /home/juliette/Documents/Genet_des_Pop/Fichiers_eigenstat/Merge_Panel_NeoAncien_NeoMoyen/4M2_1000G_v2_20240109/Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_20240109.geno
snpname: /home/juliette/Documents/Genet_des_Pop/Fichiers_eigenstat/Merge_Panel_NeoAncien_NeoMoyen/4M2_1000G_v2_20240109/Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_20240109.snp
indivname: /home/juliette/Documents/Genet_des_Pop/Fichiers_eigenstat/Merge_Panel_NeoAncien_NeoMoyen/4M2_1000G_v2_20240109/Merge_Panel_NeoAncien_NeoMoyen_4M21000Gv2_chr1-22_modifWHG_SitesCerny_20240109.ind
popfilename: popfile_f3out_Cerny_vs_WHG_Agri_CernySites_PapierCerny_4M2v2_20240123.txt
inbreed: YES
```

## Plot

```R
data = read.csv("resultats_f3out_Cerny_vs_WHG_Agri_CernySites_PapierCerny_4M2v2_20240123.csv", header = T, sep = "\t", dec = ".", na.strings = "NA")

pdf("plot_f3out_Cerny_vs_WHG_Agri_CernySites_PapierCerny_4M2v1_20231005.pdf", height = 10, width = 10)

ggplot(data, aes(x = f3, y = reorder(Source2, f3))) + 
  geom_pointrange(aes(xmin=f3-std.err, xmax=f3+std.err, shape = Point, color = Color), size = 0.6) + 
  scale_x_continuous(name = "f3(Cerny, test; BEB)") + 
  scale_shape_manual(name = "", values=c("EN" = 15, "MN" = 16), breaks=c("EN", "MN"), labels=c("Farmers 6000 BCE - 5000 BCE", "Farmers 5000 BCE - 4000 BCE")) + 
  scale_color_manual(name="", values=c("SE_Europe" = "#e5890d", "CentralEurope" = "#fadf8f", "SW_Europe" = "#c3ed64", "France" = "#a6cff4", "ParisBasin" = "#0247ec"), breaks=c("SE_Europe", "CentralEurope", "SW_Europe", "France", "ParisBasin"), labels=c("South-Eastern Europe", "Central Europe", "South-Western Europe", "France", "Paris basin new data")) + 
  scale_y_discrete(name = element_blank()) + 
  facet_wrap(facets = vars(Source1))+
  theme_bw()

dev.off()
```
