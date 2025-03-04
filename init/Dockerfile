FROM alpine:latest

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

RUN apk --no-cache add ca-certificates wget unzip bash
WORKDIR /data/

RUN cat <<'EOF' > /init.sh
#!/bin/bash
set -e

echo "Downloading geonames data"

if [ -f allCountries.zip ]; then
    echo "allCountries.zip exists"
else
    wget http://download.geonames.org/export/dump/allCountries.zip
    unzip allCountries.zip
fi

if [ -f alternateNames.zip ]; then
    echo "alternateNames.zip exists"
else
    wget http://download.geonames.org/export/dump/alternateNames.zip
    unzip alternateNames.zip
fi

if [ -f countryInfo.txt ]; then
    echo "countryInfo.txt exists"
else
    wget http://download.geonames.org/export/dump/countryInfo.txt
    grep -v '^#' countryInfo.txt > countryInfo.txt.tmp
    mv countryInfo.txt.tmp countryInfo.txt
fi

echo "Downloading geonames data complete"
sleep 5

exit 0
EOF

RUN chmod +x /init.sh

CMD ["/init.sh"]