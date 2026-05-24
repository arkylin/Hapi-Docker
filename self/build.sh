#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HAPI_DIR="$(cd "$SCRIPT_DIR/../../hapi" && pwd)"

ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        HAPI_ARCH="amd64"
        BINARY_DIR="bun-linux-x64-baseline"
        ;;
    aarch64|arm64)
        HAPI_ARCH="arm64"
        BINARY_DIR="bun-linux-arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

BINARY_PATH="$HAPI_DIR/cli/dist-exe/$BINARY_DIR/hapi"
if [ ! -f "$BINARY_PATH" ]; then
    echo "Binary not found: $BINARY_PATH"
    echo "Please build hapi first: cd ../hapi && bun run build:single-exe"
    exit 1
fi

cp "$BINARY_PATH" "$SCRIPT_DIR/hapi-${HAPI_ARCH}"

docker build \
    --build-arg "TARGETARCH=${HAPI_ARCH}" \
    -t "hapi:self" \
    -f "$SCRIPT_DIR/Dockerfile" \
    "$SCRIPT_DIR/"

rm -f "$SCRIPT_DIR/hapi-${HAPI_ARCH}"

echo "Built hapi:self for ${HAPI_ARCH}"
