#!/usr/bin/env bash

# uses minio mc to copy things to s3

server=bs3
dest=${server}/oscon2016

cd dist
mc cp scripts/* $dest

tar czf infra.tar.gz infra
mc cp infra.tar.gz $dest
rm infra.tar.gz 

tar czf ansible.tar.gz ansible
mc cp ansible.tar.gz $dest
rm ansible.tar.gz 