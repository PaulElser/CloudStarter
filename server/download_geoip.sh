#!/bin/bash
mkdir -p ./geoip
curl -L https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-City.mmdb -o ./geoip/GeoLite2-City.mmdb
