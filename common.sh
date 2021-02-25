#!/bin/bash

# Common script used by all others to define variables and stay DRY
DOCKER_CONTAINER='docker-kong-oidc'
DOCKER_IMAGE="local/$DOCKER_CONTAINER:2.3.2-1"
KONG_LOCAL_HTTP_PORT=${KONG_LOCAL_HTTP_PORT:-1080}
KONG_LOCAL_HTTPS_PORT=${KONG_LOCAL_HTTPS_PORT:-1443}
