#!/usr/bin/env bash

set -e

id=$1

domain="x.pifft.com"

if [[ -z $id ]]; then
  echo "usage: $0 <id>"
  exit 1
fi

name="shell.${id}"

# get id of A record
recordID=$(doctl compute domain records list $domain \
  | grep $name \
  | awk '{print $1}')

doctl compute domain records delete $domain $recordID
doctl compute droplet delete $name