#!/usr/bin/env bash

eval "$(conda shell.bash hook)"
conda activate "$(basename "${BASH_SOURCE[0]%.post-deploy.sh}")"

REPO="https://github.com/MaelLefeuvre/grups-rs.git"
BUILD_DIR="${CONDA_PREFIX}/$(basename "${REPO%.git}")"

cd "$(dirname $BUILD_DIR)"
git clone $REPO
cd $BUILD_DIR
git checkout v0.3.2

export CC="x86_64-conda-linux-gnu-gcc"
export RUSTFLAGS="-Ctarget-cpu=native"
CMAKE_C_FLAGS="-I./ -L./ -I$CONDA_PREFIX/include -L$CONDA_PREFIX/lib" \
cargo install --path . --root $CONDA_PREFIX

rm -rf "${BUILD_DIR}"
