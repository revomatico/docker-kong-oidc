#!/bin/bash

cd `readlink -f $0 | grep -o '.*/'`

. common.sh

./run.sh /usr/local/bin/kong start -v -p /usr/local/kong/ | xargs printf "Created container: %s\n"
sleep 3
RESP=`curl -sS localhost:$KONG_LOCAL_HTTP_PORT/request.php`
RET=$?
## Cleanup
docker rm -f $DOCKER_CONTAINER | xargs printf "Deleted container: %s\n\n"
if [[ $RET -eq 0 ]]; then
    echo "$RESP" | grep -oP '(?<=<li>)[^<]+'
    echo ""
    echo "Success!!!"
else
    echo "!!!!!FAILED with code $RET!!!!!"
    exit $RET
fi
