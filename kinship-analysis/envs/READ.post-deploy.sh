#!/usr/bin/env bash

eval "$(conda shell.bash hook)"
conda activate "$(basename "${BASH_SOURCE[0]%.post-deploy.sh}")"

cd $CONDA_PREFIX/bin

git clone https://bitbucket.org/tguenther/read.git

cp read/READ.py read/READscript.R .

chmod +x READ.py
chmod +x READscript.R

rm -rf ./read
