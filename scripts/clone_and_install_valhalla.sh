#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status

# set proxy
http_proxy=http://10.55.123.98:3333
https_proxy=http://10.55.123.98:3333

git clone --recurse-submodules --single-branch -b dev https://github.com/lqh2307/valhalla.git

cd valhalla

git submodule sync && git submodule update --init --recursive

# switch back to -DCMAKE_BUILD_TYPE=RelWithDebInfo if you want debug symbols
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc -DENABLE_SINGLE_FILES_WERROR=Off
make -C build -j$(nproc)
make -C build install

cd ..
