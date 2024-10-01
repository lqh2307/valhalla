#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status

rm -rf build

# switch back to -DCMAKE_BUILD_TYPE=RelWithDebInfo if you want debug symbols
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc -DENABLE_SINGLE_FILES_WERROR=Off
make -C build -j$(nproc)
sudo make -C build install
