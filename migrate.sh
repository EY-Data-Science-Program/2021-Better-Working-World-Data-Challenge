#! /usr/bin/env bash

# Parse commands and options
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -c|--container)
      _CONTAINER=$2
      shift
    ;;
    -h|--help)
      _HELP=1
    ;;
    -a|--all)
      _ALL=1
    ;;
    -v|--verbose)
      _VERBOSE=1
    ;;
    -f|--file)
      _FILE=$2
      shift
    ;;
    *)
      _commands="$_commands $key"
    ;;
  esac
  shift || true
done

# Reset remaining, unmatched arguments
set -- $_commands

if [ "$_HELP" ]; then cat >&2 <<EOS
Usage: $0 [options]
This script will take a list of S3 objects from a file and copy them to the
target Blob container. Any files in the same folder as the S3 object will also be copied.
Options:
  -h,--help        Show this help and exit
  -c,--container   Storage blob container to upload to
  -f,--file        Path to the file containing a list of source S3 objects.
  -a,--all         Copy all objects without prompting
EOS
exit; fi

mkdir -p tmp
_BLOB="https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${_CONTAINER}"

echo File: $_FILE

while read -u 3 _LINE; do
  echo "Source Object: $_LINE"

  if [ -z "$_ALL" ]; then
    read -n 1 -p "Begin Transfer? [ync]: " _CHOICE
    echo

    case $_CHOICE in
    y) echo Begin transfer     ;;
    c) echo Cancel; exit       ;;
    *) echo Skipping; continue ;;
    esac
  fi

  # Get "mybucket" from "s3://mybucket/path/to/file.txt"
  _BUCKET=$(echo $_LINE | cut -d/ -f 3)

  # Get bucket region
  _REGION=$(curl -sI https://$_BUCKET.s3.amazonaws.com | grep 'x-amz-bucket-region' | awk '{print $2}' | tr -d '\r')

  # Get "s3://mybucket/path/to" from "s3://mybucket/path/to/file.txt"
  _FOLDER=$(dirname $_LINE)

  # Get "path/to/" from "s3://mybucket/path/to/file.txt"
  _PREFIX=${_FOLDER:$((${#_BUCKET} + 6))}

  # Construct the source URI
  _SRC="https://$_BUCKET.s3.$_REGION.amazonaws.com/$_PREFIX"

  # Blob URI
  _DST="$_BLOB/$_PREFIX/?${AZURE_STORAGE_SAS_TOKEN}"

  echo "Bucket: $_BUCKET"
  echo "Region: $_REGION"
  echo "Folder: $_FOLDER"
  echo "Prefix: $_PREFIX"
  echo "Source: $_SRC"
  echo "Destin: $_DST"

  azcopy copy --recursive=true "$_SRC/*" "$_DST"
done 3< $_FILE