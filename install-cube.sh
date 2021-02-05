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

# Capture a password
PASSWORD="${1}"

# Do it different if it's local Docker
LOCAL="${2}"

set -ex
# Log start time
echo "Started $(date)"

# Install our dependencies
if ! [[ $LOCAL = "true" ]]; then
  export DEBIAN_FRONTEND=noninteractive
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg > docker.gpg
  apt-get update
  apt-key add docker.gpg 
  apt-key list
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt-get update && apt-get install -y docker-ce python3-pip unzip wget
  pip3 install docker-compose

  # Get our code
  wget https://codeload.github.com/EY-Data-Science-Program/2020-bushfire-challenge/zip/main?token=AAZONZRTZIVVCICMVQY3LITADTNWK -O /tmp/archive.zip
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
  sleep 10
fi

# Initialise and load a product, and then some data
# Note to future self, we can't use make here because of TTY interactivity (the -T flag)
# Initialise the datacube DB
docker-compose exec -T jupyter datacube -v system init
# Add some custom metadata
docker-compose exec -T jupyter datacube metadata add /scripts/data/metadata.eo_plus.yaml
docker-compose exec -T jupyter datacube metadata add /scripts/data/eo3_landsat_ard.odc-type.yaml
# And add some product definitions
docker-compose exec -T jupyter datacube product add /scripts/data/ga_s2a_ard_nbar_granule.odc-product.yaml
docker-compose exec -T jupyter datacube product add /scripts/data/ga_s2b_ard_nbar_granule.odc-product.yaml
docker-compose exec -T jupyter datacube product add /scripts/data/ga_ls7e_ard_3.odc-product.yaml
docker-compose exec -T jupyter datacube product add /scripts/data/ga_ls8c_ard_3.odc-product.yaml
docker-compose exec -T jupyter datacube product add /scripts/data/linescan.odc-product.yaml
# Now index some datasets
docker-compose exec -T jupyter bash -c "dc-index-from-tar --protocol https --ignore-lineage -p ga_ls7e_ard_3 -p ga_ls8c_ard_3 /scripts/data/ls78.tar.gz"
docker-compose exec -T jupyter bash -c "dc-index-from-tar --protocol https --ignore-lineage -p ga_s2a_ard_nbar_granule -p ga_s2b_ard_nbar_granule /scripts/data/s2ab.tar.gz"
docker-compose exec -T jupyter bash -c "dc-index-from-tar --protocol https --ignore-lineage -p linescan /scripts/data/linescan.tar.gz"

echo "Finished $(date)"
