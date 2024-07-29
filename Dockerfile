ARG BUILDER_IMAGE=ubuntu:23.04
ARG TARGET_IMAGE=ubuntu:23.04

FROM $BUILDER_IMAGE AS builder

# set proxy
# ARG http_proxy=http://10.55.123.98:3333
# ARG https_proxy=http://10.55.123.98:3333

ARG CONCURRENCY

ENV LD_LIBRARY_PATH=/usr/local/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/lib32:/usr/lib32

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update -y && \
  apt-get install -y sudo

WORKDIR /usr/local/src/valhalla
ADD . .
RUN ./scripts/install_deps.sh
RUN ./scripts/build_and_install.sh
RUN rm -rf /var/lib/apt/lists/*

# we wont leave the source around but we'll drop the commit hash we'll also keep the locales
WORKDIR /usr/local/src
RUN cd valhalla
RUN for f in valhalla/locales/*.json; do cat ${f} | python3 -c 'import sys; import json; print(json.load(sys.stdin)["posix_locale"])'; done > valhalla_locales
RUN rm -rf valhalla


FROM $TARGET_IMAGE AS runner

# set proxy
# ARG http_proxy=http://10.55.123.98:3333
# ARG https_proxy=http://10.55.123.98:3333

ENV LD_LIBRARY_PATH=/usr/local/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/lib32:/usr/lib32

# grab the builder stages artifacts
COPY --from=builder /usr/local /usr/local
COPY --from=builder /usr/lib/python3/dist-packages/valhalla/* /usr/lib/python3/dist-packages/valhalla/

# we need to add back some runtime dependencies for binaries and scripts
# install all the posix locales that we support
RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get install -y \
    ca-certificates \
    libcurl4 libczmq4 libluajit-5.1-2 libgdal32 \
    libprotobuf-lite32 libsqlite3-0 libsqlite3-mod-spatialite libzmq5 zlib1g \
    curl gdb locales parallel python3-minimal python3-distutils python-is-python3 \
    spatialite-bin unzip wget && \
  rm -rf /var/lib/apt/lists/*
RUN cat /usr/local/src/valhalla_locales | xargs -d '\n' -n1 locale-gen

WORKDIR /data

VOLUME /data

EXPOSE 8002
