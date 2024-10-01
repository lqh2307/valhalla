#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status

# set proxy
http_proxy=http://10.55.123.98:3333
https_proxy=http://10.55.123.98:3333

# Decide whether to use sudo?
SUDO_CMD="sudo"

if [ "$NO_USE_SUDO" = "true" ]; then
  SUDO_CMD=""
fi

# Build prime_server from source
cd third_party/prime_server
./autogen.sh && ./configure
make -j${CONCURRENCY:-$(nproc)}
$SUDO_CMD make install
cd -
