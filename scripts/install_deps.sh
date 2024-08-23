#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status

# set proxy
# http_proxy=http://10.55.123.98:3333
# https_proxy=http://10.55.123.98:3333

# Decide whether to use sudo
SUDO_CMD="sudo"

if [ "$NO_USE_SUDO" = "true" ]; then
  SUDO_CMD=""
fi

# Install the build dependencies
DEBIAN_FRONTEND=noninteractive && \
  $SUDO_CMD apt-get -y update && \
  $SUDO_CMD apt-get --no-install-recommends -y install \
    build-essential \
    ca-certificates \
    autoconf \
    automake \
    ccache \
    coreutils \
    curl \
    cmake \
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
    python3-requests \
    python3-pip \
    spatialite-bin \
    unzip \
    zlib1g-dev && \
  $SUDO_CMD apt-get -y --purge autoremove && \
  $SUDO_CMD apt-get clean && \
  $SUDO_CMD rm -rf /var/lib/apt/lists/*

# Build prime_server from source
cd third_party/prime_server
./autogen.sh
./configure
make -j${CONCURRENCY:-$(nproc)}
$SUDO_CMD make install
cd -
