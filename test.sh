#!/bin/bash

### This is not a real test. Just a quick check that kong starts just fine with some parameters.

cd `readlink -f $0 | grep -o '.*/'`

. common.sh

cleanup() {
    docker rm -f $DOCKER_CONTAINER | xargs printf "Deleted container: %s\n\n"
}

trap cleanup EXIT

./run.sh | xargs printf "Created container: %s\n"
sleep 10
if [[ -x $(which jq) ]]; then
    set -x
    curl -sSL localhost:$KONG_LOCAL_ADMIN_PORT | jq '{version,hostname,node_id}'
else
    set -x
    curl -sSL localhost:$KONG_LOCAL_ADMIN_PORT | head -2 | tail -1
fi
{ set +x; } 2>/dev/null

RESP=$(set -x; curl -sS localhost:$KONG_LOCAL_HTTP_PORT/request.php)
RET=$?
## Cleanup
if [[ $RET -eq 0 ]]; then
    echo "$RESP" | grep -oP '(?<=<li>)[^<]+'
    echo ""
    echo "Success!!!"
else
    echo "!!!!!FAILED with code $RET!!!!!"
    docker logs $DOCKER_CONTAINER
    exit $RET
fi
