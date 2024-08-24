#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status

# Decide whether to use sudo?
SUDO_CMD="sudo"

if [ "$NO_USE_SUDO" = "true" ]; then
  SUDO_CMD=""
fi

# switch back to -DCMAKE_BUILD_TYPE=RelWithDebInfo if you want debug symbols
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc -DENABLE_SINGLE_FILES_WERROR=Off
make -C build ${ADDITIONAL_TARGETS} -j${CONCURRENCY:-$(nproc)}
$SUDO_CMD make -C build install
