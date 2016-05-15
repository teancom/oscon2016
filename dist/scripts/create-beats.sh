#!/usr/bin/env bash

domain=$(cat /etc/project-domain)
id=$(cat /etc/project-id)
esURL="http://app.${id}.${domain}:9200"
name=beats-dashboards-1.1.0

curl -sSL ${esURL}/_template | grep '{}'
if [[ $? == 0 ]]; then
  echo "uploading elasticsearch templates"
  curl -o /tmp/${name}.zip -sSL https://s3.pifft.com/oscon2016/${name}.zip
  cd /tmp
  unzip ${name}.zip
  cd ${name}
  ./load.sh -l ${esURL}
else
  echo "elasticsearch templates existed on server"
fi