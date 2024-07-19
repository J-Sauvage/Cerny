# ADMIXTURE

ADMIXTURE was run on dataset 2 (see Materials and Methods section of the paper).

## ADMIXTURE on Modern populations

```bash
for K in `seq 2 15`
    do
    for i in `seq 1 20`
        do
        cd /home/juliette/Documents/Genet_des_Pop/ADMIXTURE/PapierCerny/4M2v2_LDpruned_20240115/ADMIXTURE_2/Resultats_Modern_Autosomes_Run${i}
        admixture -s time -j70 --cv ../LD_pruned_Panel4M2v2_20240229_ModernSamples_ADMIXTURE_nomissingloci.bed $K | tee admixture_ModernSamples_autosomes_Run${i}_log_${K}_20240229.txt 
    done
done
```

Plot with the package pong (https://github.com/ramachandran-lab/pong)
```bash
pong -m /home/juliette/Documents/Genet_des_Pop/ADMIXTURE/PapierCerny/4M2v2_LDpruned_20240115/ADMIXTURE_2/Plot/Modern/Admixture_pong_filemap_Modern_K2to15_run20_20240315.txt -i /home/juliette/Documents/Genet_des_Pop/ADMIXTURE/PapierCerny/4M2v2_LDpruned_20240115/ADMIXTURE_2/Plot/Modern/Admixture_pong_ind2popfile_Modern_K2to15_run20_20240315.txt
```


## ADMIXTURE on Ancient populations

```bash
for R in `seq 1 20`
do
    cd Resultats_Ancient_Autosomes_Run${R}
    for K in `seq 2 15`
    do
        cp ../Resultats_Modern_Autosomes_Run${R}/LD_pruned_Panel4M2v2_20240229_ModernSamples_ADMIXTURE_nomissingloci.$K.P LD_pruned_Panel4M2v2_20240229_AncientSamples_ADMIXTURE_nomissingloci.$K.P.in
    done
    cd ../
done


for K in `seq 2 15`
    do
    for i in `seq 1 20`
        do
        cd /home/juliette/Documents/Genet_des_Pop/ADMIXTURE/PapierCerny/4M2v2_LDpruned_20240115/ADMIXTURE_2/Resultats_Ancient_Autosomes_Run${i}
        admixture -s time -j70 --cv -P ../LD_pruned_Panel4M2v2_20240229_AncientSamples_ADMIXTURE_nomissingloci.bed $K | tee admixture_AncientSamples_autosomes_Run${i}_log_${K}_20240315.txt 
    done
done
```

Plot with the package pong (https://github.com/ramachandran-lab/pong)
```bash
pong -m /home/juliette/Documents/Genet_des_Pop/ADMIXTURE/PapierCerny/4M2v2_LDpruned_20240115/ADMIXTURE_2/Plot/Ancient/Admixture_pong_filemap_Ancient_K2to15_run20_20240628.txt -i /home/juliette/Documents/Genet_des_Pop/ADMIXTURE/PapierCerny/4M2v2_LDpruned_20240115/ADMIXTURE_2/Plot/Ancient/Admixture_pong_ind2popfile_grandespop_Ancient_K2to8_run20_20240319.txt -n /home/juliette/Documents/Genet_des_Pop/ADMIXTURE/PapierCerny/4M2v2_LDpruned_20240115/ADMIXTURE_2/Plot/Ancient/Admixture_pong_poporder_grandespop_Ancient_K2to8_run20_20240319.txt
```
