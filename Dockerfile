FROM ubuntu:focal

# https://github.com/rust-transit/gtfs-to-geojson.git (rust app)
FROM rust:latest as builder
WORKDIR /
RUN git clone --depth=1 --branch main --single-branch https://github.com/rust-transit/gtfs-to-geojson.git
WORKDIR /gtfs-to-geojson
RUN cargo build --release
RUN strip ./target/release/gtfs-geojson

FROM ubuntu:focal
COPY --from=builder /gtfs-to-geojson/target/release/gtfs-geojson /usr/local/bin/gtfs-geojson
RUN apt-get -y update && apt-get -y install libssl-dev
RUN apt-get -y install default-jre
RUN apt-get -y install curl
RUN curl --location -O https://github.com/MobilityData/gtfs-validator/releases/download/v2.0.0/gtfs-validator-v2.0.0_cli.jar 
