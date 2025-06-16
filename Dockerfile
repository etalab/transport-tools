FROM ubuntu:noble

# https://github.com/rust-transit/gtfs-to-geojson.git (rust app)
FROM rust:latest as builder
WORKDIR /
# this repo has no tagged releases ; we pin the version based on latest verified commit instead
RUN git clone https://github.com/rust-transit/gtfs-to-geojson.git
RUN git -C gtfs-to-geojson checkout 604dd7a1f7d0f97f1a89c9b061a41e3094dfd310
WORKDIR /gtfs-to-geojson
RUN cargo build --release
RUN strip ./target/release/gtfs-geojson

# https://github.com/etalab/transport-validator.git (rust app)
WORKDIR /
# this repo has no tagged releases ; we pin the version based on latest verified commit instead
RUN git clone https://github.com/etalab/transport-validator.git
RUN git -C transport-validator checkout 89abe6a8f6f0c45836bb40b1da3007cdab3a35bd
WORKDIR /transport-validator
RUN cargo build --release
RUN strip ./target/release/main

FROM ubuntu:noble
COPY --from=builder /gtfs-to-geojson/target/release/gtfs-geojson /usr/local/bin/gtfs-geojson
COPY --from=builder /transport-validator/target/release/main /usr/local/bin/transport-validator

RUN apt-get -y update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install libssl-dev default-jre curl git

# https://github.com/MobilityData/gtfs-validator (java app)
# https://github.com/MobilityData/gtfs-validator/releases
RUN curl --location -O https://github.com/MobilityData/gtfs-validator/releases/download/v7.1.0/gtfs-validator-7.1.0-cli.jar
RUN cp gtfs-validator-7.1.0-cli.jar /usr/local/bin

# https://github.com/MobilityData/gtfs-realtime-validator/blob/master/gtfs-realtime-validator-lib/README.md#batch-processing (java app)
# freeze by commit + self-compile for now (until https://github.com/MobilityData/gtfs-realtime-validator/issues/105 is handled)
RUN git clone https://github.com/MobilityData/gtfs-realtime-validator.git
RUN git -C gtfs-realtime-validator checkout 57146b4eb7a55e68f4655b8c3f3ffb5ed9cebff1
WORKDIR /gtfs-realtime-validator/gtfs-realtime-validator-lib
RUN apt-get -y install maven
RUN mvn package
RUN cp target/gtfs-realtime-validator-lib-1.0.0-SNAPSHOT.jar /usr/local/bin

WORKDIR /

# run each binary (as part of CI) to make sure they do not lack a dynamic dependency
RUN /usr/local/bin/gtfs-geojson --help
RUN /usr/local/bin/transport-validator --help

# the --help returns a non-zero exit code ; we grep on a well-known text as a quick test
RUN java -jar /usr/local/bin/gtfs-validator-7.1.0-cli.jar --help | grep "Location of the input GTFS ZIP"
# there is no --version or --help here currently
RUN java -jar /usr/local/bin/gtfs-realtime-validator-lib-1.0.0-SNAPSHOT.jar 2>&1 | grep "For batch mode you must provide a path and file name to GTFS data"
# freeze the JDK too (installed via default-jre, so no explicit version)
RUN java -version 2>&1
RUN java -version 2>&1 | grep "OpenJDK Runtime Environment (build 11."
