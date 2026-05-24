#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "Cloning tiann/hapi@main into $BUILD_DIR ..."
git clone --depth 1 --branch main https://github.com/tiann/hapi.git "$BUILD_DIR"

cd "$BUILD_DIR"
bun install
bun run build:single-exe

BINARY_PATH="$BUILD_DIR/cli/dist-exe/$BINARY_DIR/hapi"
if [ ! -f "$BINARY_PATH" ]; then
    echo "Binary not found: $BINARY_PATH"
    exit 1
fi

cp "$BINARY_PATH" "$SCRIPT_DIR/hapi-${HAPI_ARCH}"

docker build \
    --build-arg "TARGETARCH=${HAPI_ARCH}" \
    -t "hapi:origin" \
    -f "$SCRIPT_DIR/Dockerfile" \
    "$SCRIPT_DIR/"

rm -f "$SCRIPT_DIR/hapi-${HAPI_ARCH}"

echo "Built hapi:origin for ${HAPI_ARCH}"
