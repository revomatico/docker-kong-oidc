#!/bin/bash

# Common script used by all others to define variables and stay DRY
DOCKER_CONTAINER='kong-oidc'
DOCKER_IMAGE="local/$DOCKER_CONTAINER:1.0"

LUA_VERSION='5.1'
KONG_TPL_DIR="usr/local/share/lua/$LUA_VERSION/kong/templates"
