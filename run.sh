#!/bin/bash
echo "*Aura* Building container..."
mkdir -p result
rm -rf result/*
docker build -t aura/build . || exit
echo "*Aura* Starting build container..."
docker run \
--name aura-build \
--mount type=bind,source="$(pwd)"/result,target=/opt/bigbang/result \
--privileged \
aura/build
echo "*Aura* Removing containers..."
docker rm aura-build
