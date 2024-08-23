#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status

mkdir -p \
  data \
  data/osm \
  data/timezones \
  data/valhalla \
  data/valhalla/tiles \
  data/valhalla/transit \
  data/valhalla/transit_feeds \
  data/valhalla/elevation_tiles
