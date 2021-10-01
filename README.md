### What is this?

This repository contains a Docker setup to consolidate various converters and validators that we use or will use soon on [transport.data.gouv.fr](https://transport.data.gouv.fr):
* https://github.com/rust-transit/gtfs-to-geojson.git
* https://github.com/etalab/transport-validator.git
* https://github.com/MobilityData/gtfs-validator
* https://github.com/CUTR-at-USF/gtfs-realtime-validator/blob/master/gtfs-realtime-validator-lib/README.md#batch-processing

This is an internal build, but we are still publishing it as open-source in case it helps other (without support at this point).

### Use from Docker container registry

* Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
* Verify the available "tags" at https://github.com/etalab/transport-tools/pkgs/container/transport-tools (e.g. `master` currently, for unstable build)
* Download the GTFS file on disk in current folder (manually or with a `curl` command)
* Run the validator with:

```
docker run -a stdout -a stderr -v $(pwd):/data -t ghcr.io/etalab/transport-tools:master java -jar gtfs-validator-v2.0.0_cli.jar -o /data -f fr-foobar -i /data/"the-gtfs-file.zip"
```

Explanation:
* `-a stdout -a stderr` makes sure you can see the output of the Docker program on your screen
* `-v $(pwd):/data` (replace with `-v %CD%:/data` on Windows) makes the current folder available inside Docker at `/data`
* `-t xyz` tells Docker which tag to use
* `java -jar xyz.jar` runs the java program contained in the "jar" archive
* `-o /data/` gives a folder where the validator will dump its output (json files)
* `-f fr-foobar` tells the validator which country is expected + feed name
* `-i /data/thefile.zip` tells the validator where is its input file (inside the Docker volume)


### Manual local use (testing etc)

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
