FROM ubuntu:focal

# https://github.com/rust-transit/gtfs-to-geojson.git (rust app)
FROM rust:latest as builder
WORKDIR /
RUN git clone --depth=1 --branch main --single-branch https://github.com/rust-transit/gtfs-to-geojson.git
WORKDIR /gtfs-to-geojson
RUN cargo build --release
RUN strip ./target/release/gtfs-geojson

# https://github.com/etalab/transport-validator.git (rust app)
WORKDIR /
RUN git clone --depth=1 --branch=master --single-branch https://github.com/etalab/transport-validator.git
WORKDIR /transport-validator
RUN cargo build --release
RUN strip ./target/release/main

# https://github.com/CanalTP/transit_model/tree/master/gtfs2netexfr (rust app)
# We need `proj` to be installed for the `proj_sys` crate to compile. The various options considered were:
# - `apt-get install proj-bin` (compilation fails with error `pkg-config` won't find `proj.pc`)
# - `apt-get install libproj-dev` (compilation fails because this install proj 7 and we need proj >= 8)
# - `make install_proj[_deps]` (https://github.com/CanalTP/transit_model/blob/master/Makefile) ; it works if we
#   add `apt-get install sudo` which is missing, but takes a very long time at the moment
# - relying on https://hub.docker.com/r/kisiodigital/rust-ci, which provides a `proj` flavour (see
#   https://github.com/CanalTP/ci-images/blob/master/rust/proj/Dockerfile)
#
# We could also probably "just" grab the `proj-ci` artefacts with a bit more time here:
# - https://hub.docker.com/r/kisiodigital/proj-ci
# - https://github.com/CanalTP/ci-images
#
FROM kisiodigital/rust-ci:latest-proj8.1.0 as builder_proj
WORKDIR /
RUN git clone --depth=1 --branch=master --single-branch https://github.com/CanalTP/transit_model
WORKDIR /transit_model
# NOTE: when using the kisio rust-ci as a base image, CARGO_TARGET_DIR is set to something like `/tmp/cargo-release`.
# To avoid breaking the build in case of variable change upstream, we instead force the build to be local, which
# makes the COPY step in the next stage more reliable too. Useful debugging tips including `RUN env`, and adding `--verbose`
RUN CARGO_TARGET_DIR=./target cargo build --manifest-path=gtfs2netexfr/Cargo.toml --release
RUN strip ./target/release/gtfs2netexfr

FROM ubuntu:focal
COPY --from=builder /gtfs-to-geojson/target/release/gtfs-geojson /usr/local/bin/gtfs-geojson
COPY --from=builder /transport-validator/target/release/main /usr/local/bin/transport-validator
COPY --from=builder_proj /transit_model/target/release/gtfs2netexfr /usr/local/bin/gtfs2netexfr
RUN apt-get -y update && apt-get -y install libssl-dev
RUN apt-get -y install default-jre
RUN apt-get -y install curl
# https://github.com/MobilityData/gtfs-validator (java app)
RUN curl --location -O https://github.com/MobilityData/gtfs-validator/releases/download/v2.0.0/gtfs-validator-v2.0.0_cli.jar 
# https://github.com/CUTR-at-USF/gtfs-realtime-validator/blob/master/gtfs-realtime-validator-lib/README.md#batch-processing (java app)
RUN curl --location -O https://s3.amazonaws.com/gtfs-rt-validator/travis_builds/gtfs-realtime-validator-lib/1.0.0-SNAPSHOT/gtfs-realtime-validator-lib-1.0.0-SNAPSHOT.jar

COPY --from=builder_proj /usr/lib/libproj.* /usr/lib
RUN /usr/local/bin/gtfs2netexfr --help
