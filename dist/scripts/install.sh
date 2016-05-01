#!/usr/bin/env bash

# installs shell components

set -e

workDir=/tmp/.install
playbook=${workDir}/bootstrap.yml
user=workshop
webHookURL="https://devconfbot.ngrok.io/webhook"
id=$(cat /etc/project-id)

mkdir -p $workDir

curl -sL https://s3.pifft.com/oscon2016/shell.yml > $playbook

sudo ansible-playbook $playbook
sudo rm -rf /home/${user}/.ansible
sudo rm -rf /tmp/.install

curl -X "POST" $webHookURL \
  -H "Content-Type: application/json" \
  -d "{\"type\": \"install_complete\", \"project_id\": \"$id\"}"
