#!/bin/bash

# Script to build manylinux wheels using Docker.
# Must be run from the project root.
# Requires Docker (run as root or a user in the docker group).

set -e -x

docker run --rm -v "$(pwd)":/io:Z quay.io/pypa/manylinux_2_28_x86_64 bash /io/scripts/docker_build.sh
