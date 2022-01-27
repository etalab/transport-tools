FROM ubuntu:focal

# https://github.com/rust-transit/gtfs-to-geojson.git (rust app)
FROM rust:latest as builder
WORKDIR /
# this repo has no tagged releases ; we pin the version based on latest verified commit instead
RUN git clone https://github.com/rust-transit/gtfs-to-geojson.git
RUN git -C gtfs-to-geojson checkout 3f21e496e433704cf879ee453eaa4cb41cf06e7c
WORKDIR /gtfs-to-geojson
RUN cargo build --release
RUN strip ./target/release/gtfs-geojson

# https://github.com/etalab/transport-validator.git (rust app)
WORKDIR /
# this repo has no tagged releases ; we pin the version based on latest verified commit instead
RUN git clone https://github.com/etalab/transport-validator.git
RUN git -C transport-validator checkout 302e62e787dc28b80f9e8e80ceadc80be71aafbc
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
# we pin the version to avoid unexpected changes due to rebuild on our side
RUN git clone --depth=1 --branch=v0.46.0 --single-branch https://github.com/CanalTP/transit_model
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

RUN apt-get -y update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install libssl-dev default-jre curl git

# https://github.com/MobilityData/gtfs-validator (java app)
# https://github.com/MobilityData/gtfs-validator/releases
RUN curl --location -O https://github.com/MobilityData/gtfs-validator/releases/download/v3.0.0/gtfs-validator-v3.0.0_cli.jar
# https://github.com/CUTR-at-USF/gtfs-realtime-validator/blob/master/gtfs-realtime-validator-lib/README.md#batch-processing (java app)
# freeze by commit + self-compile for now (https://github.com/CUTR-at-USF/gtfs-realtime-validator/issues/406)
RUN git clone https://github.com/CUTR-at-USF/gtfs-realtime-validator.git
RUN git -C gtfs-realtime-validator checkout fca9c73b3d3b377c606065648750b777d36ad553
WORKDIR /gtfs-realtime-validator/gtfs-realtime-validator-lib
RUN apt-get -y install maven
RUN mvn package
RUN cp target/gtfs-realtime-validator-lib-1.0.0-SNAPSHOT.jar /usr/local/bin

WORKDIR /

# for gtfs2netexfr
RUN apt-get -y install libtiff5 libcurl3-nss
# hackish ; TODO: check out https://github.com/CanalTP/ci-images instead
COPY --from=builder_proj /usr/lib/libproj.* /usr/lib
# home of proj.db
RUN mkdir /usr/share/proj/
COPY --from=builder_proj /usr/share/proj/ /usr/share/proj/

# run each binary (as part of CI) to make sure they do not lack a dynamic dependency
RUN /usr/local/bin/gtfs-geojson --help
RUN /usr/local/bin/transport-validator --help
RUN /usr/local/bin/gtfs2netexfr --help

# the --help returns a non-zero exit code ; we grep on a well-known text as a quick test
RUN java -jar gtfs-validator-v3.0.0_cli.jar --help | grep "Location of the input GTFS ZIP"

# TODO: test java binaries (they do not have a `--help` currently I believe)
