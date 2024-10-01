#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status

# set proxy
http_proxy=http://10.55.123.98:3333
https_proxy=http://10.55.123.98:3333

git clone --recurse-submodules --single-branch -b master https://github.com/kevinkreiser/prime_server.git

cd prime_server

git submodule sync && git submodule update --init --recursive

./autogen.sh && ./configure
make -j$(nproc)
make install

cd ..
