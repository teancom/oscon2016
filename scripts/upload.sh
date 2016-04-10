#!/usr/bin/env bash

# uses minio mc to copy things to s3

server=bs3
dest=${server}/oscon2016

cd dist
mc cp scripts/* $dest

dir=$(mktemp -d)

for i in infra ansible deploy; do
  archive=$dir/$i.tar.gz
  tar czf $archive $i
  mc cp $archive $dest
done

rm -rf $dir
