#!/bin/bash

if [ $# -lt 1 ]; then
  cat <<EOS
Usage:
  ./install-cube.sh PASSWORD

Arguments:
  PASSWORD    # Password to set for Jupyter login
EOS
exit 1
fi

PASSWORD="${1}"

set -ex
# Log start time
echo "Started $(date)"

# Install our dependencies
export DEBIAN_FRONTEND=noninteractive
curl -fsSL https://download.docker.com/linux/ubuntu/gpg > docker.gpg
apt-get update
apt-key add docker.gpg 
apt-key list
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update && apt-get install -y docker-ce python3-pip unzip wget
pip3 install docker-compose

# Get our code
wget https://github.com/EY-Data-Science-Program/2020-bushfire-challenge/archive/main.zip -O /tmp/archive.zip
unzip /tmp/archive.zip
mv 2020-bushfire-challenge-main /opt/odc

# We need to change some local vars.
sed --in-place "s/secretpassword/${PASSWORD}/g" /opt/odc/docker-compose.yml

# We need write access in these places
chmod -R 777 /opt/odc/notebooks
cd /opt/odc

# Start the machines
docker-compose up -d

# Wait for them to wake up
sleep 5

# Initialise and load a product, and then some data
# Note to future self, we can't use make here because of TTY interactivity (the -T flag)
# Initialise the datacube DB
docker-compose exec -T jupyter datacube -v system init
# Add some custom metadata
docker-compose exec -T jupyter datacube metadata add https://raw.githubusercontent.com/opendatacube/datacube-alchemist/local-dev-env/metadata.eo_plus.yaml
docker-compose exec -T jupyter datacube metadata add https://raw.githubusercontent.com/GeoscienceAustralia/digitalearthau/develop/digitalearthau/config/eo3/eo3_landsat_ard.odc-type.yaml
# And add some product definitions
docker-compose exec -T jupyter datacube product add https://raw.githubusercontent.com/GeoscienceAustralia/dea-config/master/products/ga_s2_ard_nbar/ga_s2_ard_nbar_granule.yaml
docker-compose exec -T jupyter datacube product add https://raw.githubusercontent.com/GeoscienceAustralia/digitalearthau/develop/digitalearthau/config/eo3/products-aws/ard_ls8.odc-product.yaml
docker-compose exec -T jupyter datacube product add https://raw.githubusercontent.com/GeoscienceAustralia/digitalearthau/develop/digitalearthau/config/eo3/products-aws/ard_ls7.odc-product.yaml
docker-compose exec -T jupyter datacube product add /scripts/linescan.odc-product.yaml
# Now index some datasets
docker-compose exec -T jupyter bash -c "cat /scripts/s-2-vic-scenes.txt | s3-to-tar --no-sign-request | dc-index-from-tar --ignore-lineage"
docker-compose exec -T jupyter bash -c "cat /scripts/ls7-vic-scenes.txt | s3-to-tar --no-sign-request | dc-index-from-tar --ignore-lineage"
docker-compose exec -T jupyter bash -c "cat /scripts/ls8-vic-scenes.txt | s3-to-tar --no-sign-request | dc-index-from-tar --ignore-lineage"
docker-compose exec -T jupyter bash -c "s3-find --no-sign-request s3://dea-public-data/projects/ey-2020-bushfire-challenge/**/*.odc-dataset.json | s3-to-tar --no-sign-request | dc-index-from-tar"

echo "Finished $(date)"
