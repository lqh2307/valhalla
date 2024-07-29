#!/usr/bin/env bash
# Script for shared dependencies

set -x -o errexit -o pipefail -o nounset

http_proxy=http://10.55.123.98:3333
https_proxy=http://10.55.123.98:3333

# Install the build dependencies
DEBIAN_FRONTEND=noninteractive && \
  sudo apt-get update --assume-yes && \
  sudo apt install --yes --quiet \
    autoconf \
    automake \
    ccache \
    clang \
    clang-tidy \
    coreutils \
    curl \
    cmake \
    g++ \
    gcc \
    git \
    jq \
    lcov \
    libboost-all-dev \
    libcurl4-openssl-dev \
    libczmq-dev \
    libgdal-dev \
    libgeos++-dev \
    libgeos-dev \
    libluajit-5.1-dev \
    liblz4-dev \
    libprotobuf-dev \
    libspatialite-dev \
    libsqlite3-dev \
    libsqlite3-mod-spatialite \
    libtool \
    libzmq3-dev \
    lld \
    locales \
    luajit \
    make \
    osmium-tool \
    parallel \
    pkgconf \
    protobuf-compiler \
    python3-all-dev \
    python3-shapely \
    python3-pip \
    spatialite-bin \
    unzip \
    zlib1g-dev

git submodule sync && git submodule update --init --recursive

# build prime_server from source
cd third_party/prime_server
./autogen.sh && ./configure
make -j${CONCURRENCY:-$(nproc)}
sudo make install
cd -

sudo PIP_BREAK_SYSTEM_PACKAGES=1 python3 -m pip install --upgrade requests shapely
