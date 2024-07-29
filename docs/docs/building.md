We aim to make Valhalla installable on every half-modern hardware, platform and architecture. If the below instructions are not working for you, we'd be happy if you [file an issue or open a PR with a fix](https://github.com/valhalla/valhalla/blob/master/CONTRIBUTING.md).

### Build Configuration (all platforms)

Valhalla uses CMake as build system. When compiling with `gcc` (GNU Compiler Collection), currently version 5 or newer is supported.

Important build options include:

| Option | Behavior |
|--------|----------|
| `-DENABLE_TOOLS` (`On`/`Off`) | Build `valhalla_service` and other utilities (defaults to on)|
| `-DENABLE_DATA_TOOLS` (`On`/`Off`) | Build the data preprocessing tools (defaults to on)|
| `-DENABLE_HTTP` (`On`/`Off`) | Build with `curl` support (defaults to on)|
| `-DENABLE_PYTHON_BINDINGS` (`On`/`Off`) | Build the python bindings (defaults to on)|
| `-DENABLE_SERVICES` (`On` / `Off`) | Build the HTTP service (defaults to on)|
| `-DENABLE_THREAD_SAFE_TILE_REF_COUNT` (`ON` / `OFF`) | If ON uses shared_ptr as tile reference (i.e. it is thread safe, defaults to off)|
| `-DENABLE_CCACHE` (`On` / `Off`) | Speed up incremental rebuilds via ccache (defaults to on)|
| `-DENABLE_BENCHMARKS` (`On` / `Off`) | Enable microbenchmarking (defaults to on)|
| `-DENABLE_TESTS` (`On` / `Off`) | Enable Valhalla tests (defaults to on)|
| `-DENABLE_COVERAGE` (`On` / `Off`) | Build with coverage instrumentalisation (defaults to off)|
| `-DBUILD_SHARED_LIBS` (`On` / `Off`) | Build static or shared libraries (defaults to off)|
| `-DENABLE_STATIC_LIBRARY_MODULES` (`On` / `Off`) | If ON builds Valhalla modules as STATIC library targets (defaults to off)|
| `-DENABLE_COMPILER_WARNINGS` (`ON` / `OFF`) | Build with common compiler warnings (defaults to off)|
| `-DENABLE_SINGLE_FILES_WERROR` (`ON` / `OFF`) | Convert compiler warnings to errors for a (growing) selection of files (defaults to on)|
| `-DENABLE_WERROR` (`ON` / `OFF`) | Treat compiler warnings as errors  (defaults to off). Requires `-DENABLE_COMPILER_WARNINGS=ON` to take effect.|
| `-DENABLE_SANITIZERS` (`ON` / `OFF`) | Build with all the integrated sanitizers (defaults to off).|
| `-DENABLE_ADDRESS_SANITIZER` (`ON` / `OFF`) | Build with address sanitizer (defaults to off).|
| `-DENABLE_UNDEFINED_SANITIZER` (`ON` / `OFF`) | Build with undefined behavior sanitizer (defaults to off).|
| `-DPREFER_SYSTEM_DEPS` (`ON` / `OFF`) | Whether to use internally vendored headers or find the equivalent external package (defaults to off).|
| `-DENABLE_GDAL` (`ON` / `OFF`) | Whether to include GDAL as a dependency (used for GeoTIFF serialization of isochrone grid) (defaults to off).|

### Building from Source - Linux

To install on a Debian or Ubuntu system you need to install its dependencies with:

```bash
./scripts/install_deps.sh
```

Now you can build and install Valhalla, e.g. 

```bash
# will build to ./build
cmake -B build -DCMAKE_BUILD_TYPE=Release
make -C build -j$(nproc)
sudo make -C build install
```

#### Troubleshooting

- if the build fails on something with `date_time`, chances are you don't have [`make`](https://gnuwin32.sourceforge.net/packages/make.htm) and/or [`awk`](https://gnuwin32.sourceforge.net/packages/gawk.htm) installed, which is needed to properly configure `third_party/tz`. Even so, it might still fail because the used MS shell can't handle `mv` properly. In that case simply mv `third_party/tz/leapseconds.out` to `third_party/tz/leapseconds` and start the build again

### Include Valhalla as a project dependency

When importing `libvalhalla` as a dependency in a project, it's important to know that we're using both CMake and `pkg-config` to resolve our own dependencies. Check the root `CMakeLists.txt` for details. This is important in case you'd like to bring your own dependencies, such as cURL or protobuf. It's always safe to use `PKG_CONFIG_PATH` environment variable to point CMake to custom installations, however, for dependencies we resolve with `find_package` you'll need to check CMake's built-in `Find*` modules on how to provide the proper paths.

To resolve `libvalhalla`'s linker/library paths/options, we recommend to use `pkg-config` or `pkg_check_modules` (in CMake).

Currently, `rapidjson`, `date` & `dirent` (Win only) headers are vendored in `third_party`. Consuming applications are encouraged to use `pkg-config` to resolve Valhalla and its dependencies which will automatically install those headers to `/path/to/include/valhalla/third_party/{rapidjson, date, dirent.h}` and can be `#include`d appropriately.

## Running Valhalla server on Unix

The following script should be enough to make some routing data and start a server using it. (Note - if you would like to run an elevation lookup service with Valhalla follow the instructions [here](./elevation.md)).

```bash
# download some data and make tiles out of it
# NOTE: you can feed multiple extracts into pbfgraphbuilder
wget http://download.geofabrik.de/europe/switzerland-latest.osm.pbf http://download.geofabrik.de/europe/liechtenstein-latest.osm.pbf
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
