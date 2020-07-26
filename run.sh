#!/bin/bash

. common.sh

docker run --rm -it \
    --name $DOCKER_CONTAINER \
    $DOCKER_IMAGE \
    sh -c "$*"
