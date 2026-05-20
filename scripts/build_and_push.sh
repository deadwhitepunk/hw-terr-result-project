#!/bin/bash
set -e

REGISTRY_ID=$1
REPO_NAME=$2

echo "Configuring Docker credential helper..."
yc container registry configure-docker

echo "Building Docker image..."
cd ../app
docker build -f Dockerfile.python -t cr.yandex/${REGISTRY_ID}/${REPO_NAME}:latest .

echo "Pushing to registry..."
docker push cr.yandex/${REGISTRY_ID}/${REPO_NAME}:latest

echo "Done!"