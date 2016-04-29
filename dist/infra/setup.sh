#!/usr/bin/env bash

set -x

projectID=$(cat /etc/project-id)

keyFile=$HOME/.ssh/id_rsa
if [[ ! -f $keyFile ]]; then
  ssh-keygen -f $keyFile -t rsa -N ''
  cat $HOME/.ssh/id_rsa.pub > $HOME/.ssh/authorized_keys
  chmod 600 $HOME/.ssh/authorized_keys
fi

if [[ ! -f terraform.tfvars ]]; then
  fingerprint=$(ssh-keygen -lf ${keyFile}.pub | awk '{print $2}' | sed 's/MD5://')
  publicKey=$(cat ${keyFile}.pub)

  doctl compute ssh-key get "$fingerprint" > /dev/null
  if [[ $? == 1 ]]; then
    doctl compute ssh-key create oscon-$projectID --public-key "$publicKey"
  fi

  read -r -d '' tfVars << EOF
do_token="$(cat /etc/digitalocean-token)"
private_key="${keyFile}"
ssh_fingerprint="${fingerprint}"
region="nyc1"
project="${projectID}"
domain="x.pifft.com"
public_key="${publicKey}"
EOF
  echo "${tfVars}" > terraform.tfvars
fi

terraform get
terraform apply