#!/usr/bin/env bash

set -e


id=$1

domain="x.pifft.com"

if [[ -z $id ]]; then
  echo "usage: $0 <id>"
  exit 1
fi

name="shell.${id}"

# delete A records
doctl compute domain records list $domain \
  | grep "\.${id}" \
  | awk '{print $1}' \
  | xargs doctl compute domain records delete $domain

# delete droplets
doctl compute droplet list "*.${id}" --no-header --format ID \
  | xargs doctl compute droplet rm

# delete keys
doctl compute ssh-key list \
  | grep "oscon-${id}" \
  | awk '{print $1}' \
  | xargs -I % doctl compute ssh-key delete %