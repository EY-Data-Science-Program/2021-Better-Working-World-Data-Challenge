# You can follow the steps below in order to get yourself a local ODC.
# Once running, you can access a Jupyter environment 
# at 'http://localhost' with password 'secretpassword'

# 1. Start your Docker environment
up:
	docker-compose up

# Delete everything
down:
	docker-compose down

# 2. Prepare the database
initdb:
	docker-compose exec jupyter \
		datacube -v system init

# 3.a Add a metadata definition for Sentinel-2
prepare:
	./install-cube.sh secretpassword true

# Find Sentinel-2, Landsat 7 and Landsat 8 scenes over Victoria
# First search for all scenes... careful, this takes a very long time.
find-s-2-documents:
	docker-compose exec jupyter \
		bash -c \
			"s3-find --no-sign-request s3://dea-public-data/L2/sentinel-2-nbar/S2MSIARD_NBAR/**/ARD-METADATA.yaml \
		 	| gzip > /scripts/s-2-all-scenes.txt.gz"

find-ls7-documents:
	docker-compose exec jupyter \
		bash -c \
			"s3-find --no-sign-request s3://dea-public-data/baseline/ga_ls7e_ard_3/**/*.odc-metadata.yaml \
		 	| gzip > /scripts/ls7-all-scenes.txt.gz"

find-ls8-documents:
	docker-compose exec jupyter \
		bash -c \
			"s3-find --no-sign-request s3://dea-public-data/baseline/ga_ls8c_ard_3/**/*.odc-metadata.yaml \
		 	| gzip > /scripts/ls8-all-scenes.txt.gz"

# Next extract the area of interest using pathrows or MGRS tiles and dates
scripts/dates.txt:
	./make_dates.sh > ./scripts/dates.txt

filter-s-2-documents:
	docker-compose exec jupyter \
		bash -c \
			"gunzip -c /scripts/s-2-all-scenes.txt.gz \
			| grep -f /scripts/vic-tiles-s-2.txt \
			| grep -f /scripts/dates.txt > /scripts/s-2-vic-scenes.txt"

filter-ls7-documents:
	docker-compose exec jupyter \
		bash -c \
			"gunzip -c /scripts/ls7-all-scenes.txt.gz \
			| grep -f /scripts/vic-tiles-ls.txt \
			| grep -f /scripts/dates.txt > /scripts/ls7-vic-scenes.txt"

filter-ls8-documents:
	docker-compose exec jupyter \
		bash -c \
			"gunzip -c /scripts/ls8-all-scenes.txt.gz \
			| grep -f /scripts/vic-tiles-ls.txt \
			| grep -f /scripts/dates.txt > /scripts/ls8-vic-scenes.txt"

# Some extra commands to help in managing things.
# Rebuild the image
build:
	docker-compose build

# Start an interactive shell
shell:
	docker-compose exec jupyter bash

# OTHER
metadata-landsat:
	docker-compose exec jupyter \
		datacube metadata add https://raw.githubusercontent.com/GeoscienceAustralia/digitalearthau/develop/digitalearthau/config/eo3/eo3_landsat_ard.odc-type.yaml

product-landsat:
	docker-compose exec jupyter \
		bash -c "\
			datacube product add https://raw.githubusercontent.com/GeoscienceAustralia/digitalearthau/develop/digitalearthau/config/eo3/products-aws/ard_ls5.odc-product.yaml;\
			datacube product add https://raw.githubusercontent.com/GeoscienceAustralia/digitalearthau/develop/digitalearthau/config/eo3/products-aws/ard_ls7.odc-product.yaml;\
			datacube product add https://raw.githubusercontent.com/GeoscienceAustralia/digitalearthau/develop/digitalearthau/config/eo3/products-aws/ard_ls8.odc-product.yaml;"


index-landsat:
	docker-compose exec jupyter \
		bash -c "\
			s3-find --no-sign-request "s3://dea-public-data-dev/analysis-ready-data/ga_ls8c_ard_3/**/*.odc-metadata.yaml"\
			| s3-to-tar --no-sign-request | dc-index-from-tar --product ga_ls8c_ard_3 --ignore-lineage"

index-landsat-one:
	docker-compose exec jupyter \
		datacube dataset add --ignore-lineage --confirm-ignore-lineage \
		https://dea-public-data-dev.s3-ap-southeast-2.amazonaws.com/analysis-ready-data/ga_ls8c_ard_3/115/074/2013/05/20/ga_ls8c_ard_3-0-0_115074_2013-05-20_final.proc-info.yaml


# CLOUD FORMATION
# Update S3 template (this is owned by Digital Earth Australia)
upload-s3:
	aws s3 cp cube-in-a-box-dea-cloudformation.yml s3://opendatacube-cube-in-a-box/ --acl public-read

# This section can be used to deploy onto CloudFormation instead of the 'magic link'
create-infra:
	aws cloudformation create-stack \
		--region ap-southeast-2 \
		--stack-name odc-test \
		--template-body file://cube-in-a-box-dea-cloudformation.yml \
		--parameter file://parameters.json \
		--tags Key=Name,Value=OpenDataCube \
		--capabilities CAPABILITY_NAMED_IAM
