#!/usr/bin/env bash

source env.sh
rm -rf docker-compose.yml
envsubst < "template.yml" > "docker-compose.yml"

docker-compose -H swarm-1:4000 $@