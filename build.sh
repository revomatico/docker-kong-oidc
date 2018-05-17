#!/bin/bash

cd $(readlink -f ${0%/*})
. common.sh

# Alter the default nginx_kong.lua template to accomodate the kong-oidc plugin
[[ ! -d "$KONG_TPL_DIR" ]] &&
    mkdir -p "$KONG_TPL_DIR"
wget https://raw.githubusercontent.com/Kong/kong/master/kong/templates/nginx_kong.lua -O - | \
    sed "/server_name kong;/a set_decode_base64 \$session_secret '`openssl rand -base64 32`';" > "$KONG_TPL_DIR/nginx_kong.lua"

docker build \
    --force-rm \
    -t $DOCKER_IMAGE \
    .

# List image in docker
docker images $DOCKER_IMAGE
