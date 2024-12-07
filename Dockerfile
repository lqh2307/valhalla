ARG BUILDER_IMAGE=ubuntu:24.04
ARG TARGET_IMAGE=ubuntu:24.04

FROM ${BUILDER_IMAGE} AS builder

# set proxy
# ARG http_proxy=http://10.55.123.98:3333
# ARG https_proxy=http://10.55.123.98:3333

WORKDIR /usr/local/src

<<<<<<< HEAD
# Install the build dependencies
RUN \
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
    curl \
    git \
    wget \
    coreutils \
    jq \
    lcov \
    lld \
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
    locales \
    luajit \
    spatialite-bin \
    osmium-tool \
    parallel \
    protobuf-compiler \
    python3-all-dev \
    python3-requests \
    python3-pip \
    zlib1g-dev \
  && apt-get -y --purge autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
=======
# the binaries are huge with all the symbols so we strip them but keep the debug there if we need it
#WORKDIR /usr/local/bin
#RUN for f in valhalla_*; do objcopy --only-keep-debug $f $f.debug; done
#RUN tar -cvf valhalla.debug.tar valhalla_*.debug && gzip -9 valhalla.debug.tar
#RUN rm -f valhalla_*.debug
#RUN strip --strip-debug --strip-unneeded valhalla_* || true
#RUN strip /usr/local/lib/libvalhalla.a
#RUN strip /usr/local/lib/python3.12/dist-packages/valhalla/python_valhalla*.so
>>>>>>> d98654aaf2753ee7c3e45542a5d63be0ea0cf8ad

# Build prime_server
RUN \
  git clone --recurse-submodules --single-branch -b master https://github.com/kevinkreiser/prime_server.git \
  && cd prime_server \
  && git submodule sync && git submodule update --init --recursive \
  && ./autogen.sh && ./configure \
  && make -j$(nproc) \
  && make install \
  && cd .. \
  && rm -rf prime_server

# Build valhalla
RUN \
  git clone --recurse-submodules --single-branch -b 1.0.0 https://github.com/lqh2307/valhalla.git \
  && cd valhalla \
  && git submodule sync && git submodule update --init --recursive \
  && cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc -DENABLE_SINGLE_FILES_WERROR=Off \
  && make -C build -j$(nproc) \
  && make -C build install \
  && cd .. \
  && for f in valhalla/locales/*.json; do cat ${f} | python3 -c 'import sys; import json; print(json.load(sys.stdin)["posix_locale"])'; done > valhalla_locales \
  && rm -rf valhalla


FROM ${TARGET_IMAGE} AS runner

# set proxy
# ARG http_proxy=http://10.55.123.98:3333
# ARG https_proxy=http://10.55.123.98:3333

# Install the runtime dependencies
RUN \
  export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y update \
  && apt-get -y upgrade \
  && apt-get -y install \
    ca-certificates \
    libcurl4t64 \
    libczmq4 \
    libluajit-5.1-2 \
    libgdal34t64 \
    libprotobuf-lite32 \
    libsqlite3-0 \
    libsqlite3-mod-spatialite \
    libzmq5 \
    zlib1g \
    curl \  
    osmosis \
    locales \
    parallel \
    python3-minimal \
    python-is-python3 \
    python3-requests \
    spatialite-bin \
  && apt-get -y --purge autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local /usr/local

RUN \
  ldconfig

RUN \
  cat /usr/local/src/valhalla_locales | xargs -d '\n' -n1 locale-gen

WORKDIR /

VOLUME /data

EXPOSE 8002
