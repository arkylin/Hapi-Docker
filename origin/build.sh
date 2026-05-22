#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        HAPI_ARCH="amd64"
        ;;
    aarch64|arm64)
        HAPI_ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

docker build \
    --build-arg "TARGETARCH=${HAPI_ARCH}" \
    -t "hapi:origin" \
    -f "$SCRIPT_DIR/Dockerfile" \
    "$SCRIPT_DIR/"

echo "Built hapi:origin for ${HAPI_ARCH}"
