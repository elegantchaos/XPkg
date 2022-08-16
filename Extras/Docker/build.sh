#!/bin/bash

# Build the Docker image.
docker build --platform=arm64 -t xpkg-test .