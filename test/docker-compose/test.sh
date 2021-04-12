#!/bin/bash

exit_failed() {
    echo "[FAILED] ${1:-Kong cannot reach the database or did not start}"
    exit 1
}

cd $(readlink -f ${0%/*})

. ../../common.sh

set -x

export KONG_DOCKER_TAG=$DOCKER_IMAGE

docker-compose up --force-recreate -d

sleep ${1:-10}

RET=`curl -s localhost:8001/status | grep -o '"database":{"reachable":true}'`

docker-compose ps

docker-compose down

docker-compose rm -f

docker volume rm docker-compose_kong_data

{ set +x; } 2>/dev/null
if [[ -n "$RET" ]]; then
    echo "[SUCCESS] Kong with database is up!"
else
    echo "[FAILED] Kong cannot reach the database or did not start"
    exit 1
fi
