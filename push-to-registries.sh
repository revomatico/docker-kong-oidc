#!/bin/bash

set -e -o pipefail

cd $(readlink -f ${0%/*})
. common.sh
. env.sh

## Push to optional space separated local registries
for reg in $LOCAL_REGISTRIES; do
    docker tag $DOCKER_IMAGE $reg/${DOCKER_IMAGE##*/}
    docker push $reg/${DOCKER_IMAGE##*/}
done

DH_USERNAME="${1:-$DH_USERNAME}"
DH_PASSWORD="${2:-$DH_PASSWORD}"
[[ -n "$DH_PASSWORD" ]] || read -p "Docker Hub Password for $DH_USERNAME: " -s DH_PASSWORD
DH_REPO="$DH_USERNAME/${DOCKER_IMAGE##*/}"

## Push image to Docker Hub
docker login -u $DH_USERNAME --password-stdin <<< "$DH_PASSWORD"
for tag in "$DH_REPO" "${DH_REPO%:*}:latest"; do
    docker tag $DOCKER_IMAGE "$tag"
    docker push "$tag"
done

## Update Docker Hub README
docker run --rm -v $PWD:/workspace \
  -e DOCKERHUB_USERNAME="$DH_USERNAME" \
  -e DOCKERHUB_PASSWORD="$DH_PASSWORD" \
  -e DOCKERHUB_REPOSITORY="${DH_REPO%:*}" \
  -e README_FILEPATH='/workspace/README.md' \
  peterevans/dockerhub-description:2
