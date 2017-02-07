#!/bin/bash -x

if [ ! -d "discourse_docker" ]; then
    git clone https://github.com/discourse/discourse_docker.git
    rm -rf discourse_docker/containers
    ( cd discourse_docker && ln -s ../containers containers )
fi

source ./common-variables.sh

version_label=v`date +"%Y%m%d-%H%M%S"`
docker_tag=$docker_registry/$docker_repository:$version_label

(
    cd discourse_docker
    ./launcher bootstrap app
)

docker tag local_discourse/app $docker_tag
