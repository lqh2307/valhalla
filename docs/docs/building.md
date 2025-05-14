# Build from Source

## Build Configuration (all platforms)

Valhalla uses [CMake](https://cmake.org/) as the build system, the compiler needs C++17 support.

Important build options include:

| Option | Behavior |
|--------|----------|
| `-DENABLE_TOOLS` (`On`/`Off`) | Build `valhalla_service` and other utilities (defaults to on)|
| `-DENABLE_DATA_TOOLS` (`On`/`Off`) | Build the data preprocessing tools (defaults to on)|
| `-DENABLE_HTTP` (`On`/`Off`) | Build with `curl` support (defaults to on)|
| `-DENABLE_SERVICES` (`On` / `Off`) | Build the HTTP service (defaults to on)|
| `-DENABLE_THREAD_SAFE_TILE_REF_COUNT` (`ON` / `OFF`) | If ON uses `shared_ptr` as tile reference (i.e. it is thread safe, defaults to off)|
| `-DENABLE_CCACHE` (`On` / `Off`) | Speed up incremental rebuilds via `ccache` (defaults to on)|
| `-DENABLE_STATIC_LIBRARY_MODULES` (`On` / `Off`) | If ON builds Valhalla modules as STATIC library targets (defaults to off)|
| `-DENABLE_COMPILER_WARNINGS` (`ON` / `OFF`) | Build with common compiler warnings (defaults to off)|
| `-DENABLE_WERROR` (`ON` / `OFF`) | Treat compiler warnings as errors  (defaults to off). Requires `-DENABLE_COMPILER_WARNINGS=ON` to take effect.|
| `-DPREFER_SYSTEM_DEPS` (`ON` / `OFF`) | Whether to use internally vendored headers or find the equivalent external package (defaults to off).|
| `-DENABLE_GDAL` (`ON` / `OFF`) | Whether to include GDAL as a dependency (used for GeoTIFF serialization of isochrone grid) (defaults to off).|

## Build

```bash

```

#### Troubleshooting

- if the build fails on something with `date_time`, chances are you don't have [`make`](https://gnuwin32.sourceforge.net/packages/make.htm) and/or [`awk`](https://gnuwin32.sourceforge.net/packages/gawk.htm) installed, which is needed to properly configure `third_party/tz`. Even so, it might still fail because the used MS shell can't handle `mv` properly. In that case simply mv `third_party/tz/leapseconds.out` to `third_party/tz/leapseconds` and start the build again

## Include Valhalla as a project dependency

When importing `libvalhalla` as a dependency in a project, it's important to know that we're using **both** CMake **and** [`pkg-config`](https://www.freedesktop.org/wiki/Software/pkg-config/) to resolve our own dependencies. Check the root `CMakeLists.txt` for details. This is important in case you'd like to bring your own dependencies, such as cURL or protobuf. It's always safe to use `PKG_CONFIG_PATH` environment variable to point CMake to custom installations, however, for dependencies we resolve with `find_package` you'll need to check CMake's built-in `Find*` modules on how to provide the proper paths.

To resolve `libvalhalla`'s linker/library paths/options, we recommend to use `pkg-config` or [`pkg_check_modules`](https://cmake.org/cmake/help/latest/module/FindPkgConfig.html#command:pkg_check_modules) (in CMake).

Currently, `rapidjson`, `date` & `dirent` (Windows only) headers are vendored in `third_party`. Consuming applications are encouraged to use `pkg-config` to resolve Valhalla and its dependencies which will automatically install those headers to `/path/to/include/valhalla/third_party/{rapidjson, date, dirent.h}` and can be `#include`d appropriately.

## Running Valhalla server on Unix

The following script should be enough to make some routing data and start a server using it.

!!! tip
    Instructions for [running an **elevation lookup service**](./elevation.md) with Valhalla.

```bash
# download some data and make tiles out of it
# NOTE: you can feed multiple extracts into pbfgraphbuilder
wget https://download.geofabrik.de/europe/switzerland-latest.osm.pbf https://download.geofabrik.de/europe/liechtenstein-latest.osm.pbf
# get the config and setup
mkdir -p valhalla_tiles
valhalla_build_config --mjolnir-tile-dir ${PWD}/valhalla_tiles --mjolnir-tile-extract ${PWD}/valhalla_tiles.tar --mjolnir-timezone ${PWD}/valhalla_tiles/timezones.sqlite --mjolnir-admin ${PWD}/valhalla_tiles/admins.sqlite > valhalla.json
# build timezones.sqlite to support time-dependent routing
valhalla_build_timezones > valhalla_tiles/timezones.sqlite
# build admins.sqlite to support admin-related properties such as access restrictions, driving side, ISO codes etc
valhalla_build_admins -c valhalla.json switzerland-latest.osm.pbf liechtenstein-latest.osm.pbf
# build routing tiles
valhalla_build_tiles -c valhalla.json switzerland-latest.osm.pbf liechtenstein-latest.osm.pbf
# tar it up for running the server
# either run this to build a tile index for faster graph loading times
valhalla_build_extract -c valhalla.json -v
# or simply tar up the tiles
find valhalla_tiles | sort -n | tar cf valhalla_tiles.tar --no-recursion -T -

# grab the demos repo and open up the point and click routing sample
git clone --depth=1 --recurse-submodules --single-branch --branch=gh-pages https://github.com/valhalla/demos.git
firefox demos/routing/index-internal.html &
# NOTE: set the environment pulldown to 'localhost' to point it at your own server

# start up the server
valhalla_service valhalla.json 1
# curl it directly if you like:
curl http://localhost:8002/route --data '{"locations":[{"lat":47.365109,"lon":8.546824,"type":"break","city":"Zürich","state":"Altstadt"},{"lat":47.108878,"lon":8.394801,"type":"break","city":"6037 Root","state":"Untere Waldstrasse"}],"costing":"auto","directions_options":{"units":"miles"}}' | jq '.'

#HAVE FUN!
```
