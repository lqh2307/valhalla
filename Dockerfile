FROM ubuntu:24.04 AS builder

ARG ADDITIONAL_TARGETS

RUN \
  export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y update \
  && apt-get -y install \
    build-essential \
    autoconf \
    automake \
    ccache \
    clang \
    clang-tidy \
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
    zlib1g-dev \
  && apt-get -y --purge autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ENV LD_LIBRARY_PATH=/usr/local/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/lib32:/usr/lib32

WORKDIR /usr/local/src/valhalla

ADD . .

WORKDIR /usr/local/src/valhalla/third_party/prime_server

RUN ./autogen.sh && ./configure \
  && make -j$(nproc) \
  && make install

WORKDIR /usr/local/src/valhalla/build

RUN cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=gcc \
  && make all ${ADDITIONAL_TARGETS} -j$(nproc) \
  && make install

WORKDIR /usr/local/src

RUN for f in valhalla/locales/*.json; do cat ${f} | python3 -c 'import sys; import json; print(json.load(sys.stdin)["posix_locale"])'; done > valhalla_locales


FROM ubuntu:24.04 AS runner

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y update \
  && apt-get -y install \
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
    gdb \
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
  && rm -rf /var/lib/apt/lists/*

ENV LD_LIBRARY_PATH=/usr/local/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/lib32:/usr/lib32

COPY --from=builder /usr/local /usr/local
COPY --from=builder /usr/local/lib/python3.12/dist-packages/valhalla/* /usr/local/lib/python3.12/dist-packages/valhalla/

RUN cat /usr/local/src/valhalla_locales | xargs -d '\n' -n1 locale-gen

RUN python3 -c "import valhalla,sys; print(sys.version, valhalla)"
