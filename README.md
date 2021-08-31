```
docker build . -t localtest

# https://github.com/rust-transit/gtfs-to-geojson
docker run -a stdout -t localtest /usr/local/bin/gtfs-geojson --help

# https://github.com/etalab/transport-validator.git
docker run -a stdout -t localtest /usr/local/bin/transport-validator --help

# https://github.com/MobilityData/gtfs-validator/tree/v2.0.0-docs
docker run -a stdout -t localtest java -jar gtfs-validator-v2.0.0_cli.jar

# https://github.com/CUTR-at-USF/gtfs-realtime-validator/blob/master/gtfs-realtime-validator-lib/README.md#batch-processing
docker run -a stdout -t localtest java -jar gtfs-realtime-validator-lib-1.0.0-SNAPSHOT.jar
```
