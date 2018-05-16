#!/bin/bash

. common.sh

docker run -d -it \
    -p 8000:8000 8443:8443 8001:8001 8444:8444 \
    --name $DOCKER_CONTAINER \
    $DOCKER_IMAGE
