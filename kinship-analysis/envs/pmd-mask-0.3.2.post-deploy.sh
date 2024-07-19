#!/usr/bin/env bash

eval "$(conda shell.bash hook)"
conda activate "$(basename "${BASH_SOURCE[0]%.post-deploy.sh}")" 

REPO="https://github.com/xxxxxxxxx/pmd-mask.git" #[PLACEHOLDER]
BUILD_DIR="$CONDA_PREFIX/$(basename "${REPO%.git}")"

cd $CONDA_PREFIX
git clone $REPO

cd $BUILD_DIR
git checkout v0.3.2

RUSTFLAGS="-Ctarget-cpu=native" cargo install --all-features --path . --root $CONDA_PREFIX
cd $CONDA_PREFIX
rm -rf ${BUILD_DIR}
