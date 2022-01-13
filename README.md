### What is this?

This repository contains a Docker setup to consolidate various converters and validators that we use or will use soon on [transport.data.gouv.fr](https://transport.data.gouv.fr):
* https://github.com/rust-transit/gtfs-to-geojson.git
* https://github.com/etalab/transport-validator.git
* https://github.com/CanalTP/transit_model/tree/master/gtfs2netexfr
* https://github.com/MobilityData/gtfs-validator
* https://github.com/CUTR-at-USF/gtfs-realtime-validator/blob/master/gtfs-realtime-validator-lib/README.md#batch-processing

This is an internal build, but we are still publishing it as open-source in case it helps other (without support at this point).

### Release process

To create a new release as a Docker image, just create a GitHub release: it is important that you create a tag named `v1.0.x` or similar, and that the release has the same name + changelog.

On release creation (see https://github.com/etalab/transport-tools/blob/master/.github/workflows/docker.yml), a build will start, and should normally result into the publication of a GitHub-hosted Docker image named just like the release.

You can find the release here: https://github.com/etalab/transport-tools/pkgs/container/transport-tools

One major caveat: the workflow must exist at the moment the tag is created (https://github.community/t/workflow-set-for-on-release-not-triggering-not-showing-up/16286/7):

> The trigger only executes when a release is created using a tag that contains the workflow.

### Use from Docker container registry

* Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
* Verify the available "tags" at https://github.com/etalab/transport-tools/pkgs/container/transport-tools (e.g. `master` currently, for unstable build)
* Download the GTFS file on disk in current folder (manually or with a `curl` command)
* Run the validator with:

```
docker run -a stdout -a stderr -v $(pwd):/data -t ghcr.io/etalab/transport-tools:master java -jar gtfs-validator-v2.0.0_cli.jar -o /data -f fr-foobar -i /data/"the-gtfs-file.zip"
```

You will see some output, and `report.json` and `system_errors.json` being generated with the output of the validation.

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

# https://github.com/CanalTP/transit_model/tree/master/gtfs2netexfr
docker run -a stdout -t localtest /usr/local/bin/gtfs2netexfr --help

# actual run, using a "data" subfolder shared with the docker machine (requires curl 7.73+)
curl --create-dirs --output-dir ./data -O https://data.angers.fr/api/datasets/1.0/angers-loire-metropole-horaires-reseau-irigo-gtfs-rt/alternative_exports/irigo_gtfs_zip
docker run -a stdout -a stderr -v $(pwd)/data:/data -t localtest /usr/local/bin/gtfs2netexfr -i /data/irigo_gtfs_zip -o /data --participant test

# https://github.com/MobilityData/gtfs-validator/tree/v2.0.0-docs
docker run -a stdout -t localtest java -jar gtfs-validator-v2.0.0_cli.jar

# https://github.com/CUTR-at-USF/gtfs-realtime-validator/blob/master/gtfs-realtime-validator-lib/README.md#batch-processing
docker run -a stdout -t localtest java -jar gtfs-realtime-validator-lib-1.0.0-SNAPSHOT.jar
```
