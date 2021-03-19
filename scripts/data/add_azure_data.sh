#!/usr/bin/env bash

datacube metadata add eo3_landsat_ard.odc-type.yaml
datacube metadata add eo_plus.odc-type.yaml
datacube product add ga_ls7e_ard_3.odc-product.yaml
datacube product add ga_ls8c_ard_3.odc-product.yaml
datacube product add ga_s2a_ard_nbar_granule.odc-product.yaml
datacube product add ga_s2b_ard_nbar_granule.odc-product.yaml
datacube product add linescan.odc-product.yaml
datacube product add esa_s1_rtc.odc-product.yaml

dc-index-from-tar --protocol https --ignore-lineage -p "ga_ls7e_ard_3" -p "ga_ls8c_ard_3" ls78.tar.gz
dc-index-from-tar --protocol https --ignore-lineage -p "ga_s2a_ard_nbar_granule" -p "ga_s2b_ard_nbar_granule" s2ab.tar.gz
dc-index-from-tar --protocol https --ignore-lineage -p "linescan" linescan.tar.gz
dc-index-from-tar --stac --protocol https --ignore-lineage --no-auto-add-lineage --no-verify-lineage -p "s1_rtc" sentinel1.tar.gz
