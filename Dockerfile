FROM ubuntu:focal

# https://github.com/rust-transit/gtfs-to-geojson.git (rust app)
FROM rust:latest as builder
RUN rustc --version
WORKDIR /
# this repo has no tagged releases ; we pin the version based on latest verified commit instead
RUN git clone https://github.com/rust-transit/gtfs-to-geojson.git
RUN git -C gtfs-to-geojson checkout 9ca9a25b895ba1b2fdf4d04e92895afec52d0608
WORKDIR /gtfs-to-geojson
RUN cargo build --release
RUN strip ./target/release/gtfs-geojson

# https://github.com/etalab/transport-validator.git (rust app)
# WORKDIR /
# this repo has no tagged releases ; we pin the version based on latest verified commit instead
# RUN git clone https://github.com/etalab/transport-validator.git
# RUN git -C transport-validator checkout b98d0c0d5f19a50a4c9750fd5817d8e2a857105b
# WORKDIR /transport-validator
# RUN cargo build --release
# RUN strip ./target/release/main

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
# FROM kisiodigital/rust-ci:latest-proj8.1.0 as builder_proj
# WORKDIR /
# we pin the version to avoid unexpected changes due to rebuild on our side
# RUN git clone --depth=1 --branch=v0.55.0 --single-branch https://github.com/CanalTP/transit_model
# WORKDIR /transit_model
# NOTE: when using the kisio rust-ci as a base image, CARGO_TARGET_DIR is set to something like `/tmp/cargo-release`.
# To avoid breaking the build in case of variable change upstream, we instead force the build to be local, which
# makes the COPY step in the next stage more reliable too. Useful debugging tips including `RUN env`, and adding `--verbose`
# RUN CARGO_TARGET_DIR=./target cargo build --manifest-path=gtfs2netexfr/Cargo.toml --release
# RUN strip ./target/release/gtfs2netexfr

FROM ubuntu:focal
COPY --from=builder /gtfs-to-geojson/target/release/gtfs-geojson /usr/local/bin/gtfs-geojson
# COPY --from=builder /transport-validator/target/release/main /usr/local/bin/transport-validator
# COPY --from=builder_proj /transit_model/target/release/gtfs2netexfr /usr/local/bin/gtfs2netexfr

# RUN apt-get -y update
# RUN DEBIAN_FRONTEND=noninteractive apt-get -y install libssl-dev default-jre curl git

# https://github.com/MobilityData/gtfs-validator (java app)
# https://github.com/MobilityData/gtfs-validator/releases
# RUN curl --location -O https://github.com/MobilityData/gtfs-validator/releases/download/v3.1.1/gtfs-validator-3.1.1-cli.jar
# RUN cp gtfs-validator-3.1.1-cli.jar /usr/local/bin

# https://github.com/MobilityData/gtfs-realtime-validator/blob/master/gtfs-realtime-validator-lib/README.md#batch-processing (java app)
# freeze by commit + self-compile for now (until https://github.com/MobilityData/gtfs-realtime-validator/issues/105 is handled)
# RUN git clone https://github.com/MobilityData/gtfs-realtime-validator.git
# RUN git -C gtfs-realtime-validator checkout f9472e33e3c4719311b354ef7bc747035d67b1a8
# WORKDIR /gtfs-realtime-validator/gtfs-realtime-validator-lib
# RUN apt-get -y install maven
# RUN mvn package
# RUN cp target/gtfs-realtime-validator-lib-1.0.0-SNAPSHOT.jar /usr/local/bin

# WORKDIR /

# for gtfs2netexfr
# RUN apt-get -y install libtiff5 libcurl3-nss
# hackish ; TODO: check out https://github.com/CanalTP/ci-images instead
# COPY --from=builder_proj /usr/lib/libproj.* /usr/lib
# home of proj.db
# RUN mkdir /usr/share/proj/
# COPY --from=builder_proj /usr/share/proj/ /usr/share/proj/

# run each binary (as part of CI) to make sure they do not lack a dynamic dependency
RUN /usr/local/bin/gtfs-geojson --help
# RUN /usr/local/bin/transport-validator --help
# RUN /usr/local/bin/gtfs2netexfr --help

# the --help returns a non-zero exit code ; we grep on a well-known text as a quick test
# RUN java -jar /usr/local/bin/gtfs-validator-3.1.1-cli.jar --help | grep "Location of the input GTFS ZIP"
# there is no --version or --help here currently
# RUN java -jar /usr/local/bin/gtfs-realtime-validator-lib-1.0.0-SNAPSHOT.jar 2>&1 | grep "For batch mode you must provide a path and file name to GTFS data"
# freeze the JDK too (installed via default-jre, so no explicit version)
# RUN java -version 2>&1 | grep "OpenJDK Runtime Environment (build 11."
