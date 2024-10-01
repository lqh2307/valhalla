#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status

# set proxy
http_proxy=http://10.55.123.98:3333
https_proxy=http://10.55.123.98:3333

# Decide dependency to use?
DEPENDENCY="build"

if [ "$DEPENDENCY" = "runtime" ]; then
  DEPENDENCY="runtime"
fi

if [ "$DEPENDENCY" = "build" ]; then
  # Install the build dependencies
  export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y update \
    && apt-get -y upgrade \
    && apt-get -y install \
      ca-certificates \
      build-essential \
      pkgconf \
      autoconf \
      automake \
      ccache \
      cmake \
      coreutils \
      curl \
      git \
      wget \
      jq \
      lcov \
      clang \
      clang-tidy \
      libboost-all-dev \
      libcurl4-openssl-dev \
      libczmq-dev \
      libzmq3-dev \
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
      lld \
      locales \
      luajit \
      spatialite-bin \
      osmium-tool \
      parallel \
      protobuf-compiler \
      python3-all-dev \
      python3-shapely \
      python3-requests \
      python3-pip \
      unzip \
      zlib1g-dev \
    && apt-get -y --purge autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*;
elif [ "$DEPENDENCY" = "runtime" ]; then
  # Install the runtime dependencies
  export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y update \
    && apt-get -y upgrade \
    && apt-get -y install \
      ca-certificates \
      libcurl4 \
      libczmq4 \
      libluajit-5.1-2 \
      libgdal34 \
      libprotobuf-lite32 \
      libsqlite3-0 \
      libsqlite3-mod-spatialite \
      libzmq5 \
      zlib1g \
      curl \
      locales \
      parallel \
      python3-minimal \
      python-is-python3 \
      python3-shapely \
      python3-requests \
      spatialite-bin \
      unzip \
      wget \
    && apt-get -y --purge autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*;
fi
