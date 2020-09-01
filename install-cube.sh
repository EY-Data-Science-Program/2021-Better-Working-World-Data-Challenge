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

password="${1}"

set -ex

# Install our dependencies
export DEBIAN_FRONTEND=noninteractive
curl -fsSL https://download.docker.com/linux/ubuntu/gpg > docker.gpg
apt-key add docker.gpg 
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update && apt-get install -y docker-ce python3-pip unzip wget
pip3 install docker-compose

# Get our code
wget https://github.com/opendatacube/cube-in-a-box-dea/archive/main.zip -O /tmp/archive.zip
unzip /tmp/archive.zip
mv cube-in-a-box-dea-main /opt/odc

# We need to change some local vars.
sed --in-place 's/secretpassword/${SecretPassword}/g' /opt/odc/docker-compose.yml

# We need write access in these places
chmod -R 777 /opt/odc/notebooks
cd /opt/odc

# Start the machines
docker-compose pull
docker-compose up -d

# Wait for them to wake up
sleep 5

# Initialise and load a product, and then some data
# Note to future self, we can't use make here because of TTY interactivity (the -T flag)
docker-compose exec -T jupyter datacube -v system init
docker-compose exec -T jupyter datacube metadata add https://raw.githubusercontent.com/opendatacube/datacube-alchemist/local-dev-env/metadata.eo_plus.yaml
docker-compose exec -T jupyter datacube product add https://raw.githubusercontent.com/GeoscienceAustralia/dea-config/master/products/ga_s2_ard_nbar/ga_s2_ard_nbar_granule.yaml
docker-compose exec -T jupyter bash -c "gunzip -c < /scripts/vic-scenes.tar.gz | dc-index-from-tar"

echo "Done, all done. It should work now!"