```
docker build . -t localtest
docker run -a stdout -t localtest /usr/local/bin/gtfs-geojson --help
```
