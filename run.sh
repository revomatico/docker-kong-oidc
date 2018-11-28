#!/bin/bash

. common.sh

docker run --rm -it \
    -u root \
    --name $DOCKER_CONTAINER \
    $DOCKER_IMAGE \
    bash
