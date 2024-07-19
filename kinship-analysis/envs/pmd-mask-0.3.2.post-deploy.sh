#!/usr/bin/env bash

eval "$(conda shell.bash hook)"
conda activate "$(basename "${BASH_SOURCE[0]%.post-deploy.sh}")" 

#RELEASE="https://github.com/MaelLefeuvre/pmd-mask/releases/download/v0.3.2/pmd-mask-0.3.2_x86_64-unknown-linux-gnu"
#wget -O "${CONDA_PREFIX}/bin/pmd-mask" $RELEASE

#REPO="https://github.com/MaelLefeuvre/pmd-mask.git"
REPO="git@github.com:MaelLefeuvre/pmd-mask.git"
BUILD_DIR="$CONDA_PREFIX/$(basename "${REPO%.git}")"

cd $CONDA_PREFIX
git clone $REPO

cd $BUILD_DIR
git checkout v0.3.2

RUSTFLAGS="-Ctarget-cpu=native" cargo install --all-features --path . --root $CONDA_PREFIX
cd $CONDA_PREFIX
rm -rf ${BUILD_DIR}
