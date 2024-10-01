ARG BUILDER_IMAGE=ubuntu:24.04
ARG TARGET_IMAGE=ubuntu:24.04

FROM ${BUILDER_IMAGE} AS builder

ENV LD_LIBRARY_PATH=/usr/local/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/lib32:/usr/lib32

# set proxy
ARG http_proxy=http://10.55.123.98:3333
ARG https_proxy=http://10.55.123.98:3333

ARG NO_USE_SUDO=true

WORKDIR /usr/local/src/valhalla

ADD . .

RUN \
  DEPENDENCY="build" ./scripts/install_deps.sh

RUN \
  ./scripts/install_prime_server.sh

RUN \
  ./scripts/build_and_install.sh

WORKDIR /usr/local/src

RUN \
  for f in valhalla/locales/*.json; do cat ${f} | python3 -c 'import sys; import json; print(json.load(sys.stdin)["posix_locale"])'; done > valhalla_locales \
  && rm -rf valhalla


FROM ${TARGET_IMAGE} AS runner

ENV LD_LIBRARY_PATH=/usr/local/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/lib32:/usr/lib32

# set proxy
ARG http_proxy=http://10.55.123.98:3333
ARG https_proxy=http://10.55.123.98:3333

ARG NO_USE_SUDO=true

COPY ./scripts/install_deps.sh /tmp/install_deps.sh
COPY --from=builder /usr/local /usr/local

RUN \
  DEPENDENCY="build" /tmp/install_deps.sh

RUN \
  cat /usr/local/src/valhalla_locales | xargs -d '\n' -n1 locale-gen

WORKDIR /

VOLUME /data

EXPOSE 8002

CMD [ "valhalla_auto_run" ]
