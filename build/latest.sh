#!/bin/bash
set -ue

docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"

docker build -t krates/haproxy:latest .
docker push krates/haproxy:latest