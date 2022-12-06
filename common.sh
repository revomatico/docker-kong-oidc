#!/bin/bash

# Common script used by all others to define variables and stay DRY
DOCKER_CONTAINER='docker-kong-oidc'
DOCKER_IMAGE="local/$DOCKER_CONTAINER:3.0.1-1"
KONG_LOCAL_HTTP_PORT=${KONG_LOCAL_HTTP_PORT:-180}
KONG_LOCAL_HTTPS_PORT=${KONG_LOCAL_HTTPS_PORT:-143}
