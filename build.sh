#!/bin/bash

cd $(readlink -f ${0%/*})
. common.sh

docker build \
    --force-rm \
    -t $DOCKER_IMAGE \
    . \
    $*

# List image in docker
docker images $DOCKER_IMAGE
