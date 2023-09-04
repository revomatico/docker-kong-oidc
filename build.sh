#!/bin/bash

cd $(readlink -f ${0%/*})
. common.sh

docker build \
    -t $DOCKER_IMAGE \
    . \
    $*

# List image in docker
docker images $DOCKER_IMAGE
