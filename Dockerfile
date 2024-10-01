ARG BUILDER_IMAGE=ubuntu:24.04
ARG TARGET_IMAGE=ubuntu:24.04

FROM ${BUILDER_IMAGE} AS builder

ENV LD_LIBRARY_PATH=/usr/local/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/lib32:/usr/lib32

# set proxy
ARG http_proxy=http://10.55.123.98:3333
ARG https_proxy=http://10.55.123.98:3333

WORKDIR /usr/local/src/valhalla

ADD . .

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
    coreutils \
    curl \
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
  && rm -rf /var/lib/apt/lists/*

# Build prime_server
RUN \
  cd third_party/prime_server \
  && ./autogen.sh && ./configure \
  && make -j$(nproc) \
  && make install \
  && cd ..

# Build valhalla
RUN \
  # switch back to -DCMAKE_BUILD_TYPE=RelWithDebInfo if you want debug symbols
  cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc -DENABLE_SINGLE_FILES_WERROR=Off \
  && make -C build -j$(nproc) \
  && make -C build install

WORKDIR /usr/local/src

RUN \
  for f in valhalla/locales/*.json; do cat ${f} | python3 -c 'import sys; import json; print(json.load(sys.stdin)["posix_locale"])'; done > valhalla_locales \
  && rm -rf valhalla


FROM ${TARGET_IMAGE} AS runner

ENV LD_LIBRARY_PATH=/usr/local/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/lib32:/usr/lib32

# set proxy
ARG http_proxy=http://10.55.123.98:3333
ARG https_proxy=http://10.55.123.98:3333

# Install the runtime dependencies
RUN \
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
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local /usr/local

RUN \
  cat /usr/local/src/valhalla_locales | xargs -d '\n' -n1 locale-gen

WORKDIR /

VOLUME /data

EXPOSE 8002

CMD [ "valhalla_auto_run" ]
