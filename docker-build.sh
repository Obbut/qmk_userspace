#!/bin/bash
# Docker-based QMK build script
# Works on any platform with Docker installed

set -e

# Disable MINGW path conversion for Docker volume mounts on Windows
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="qmk-userspace-builder"

# Build Docker image if needed
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo "Building QMK Docker image (this takes a few minutes on first run)..."
    docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile.qmk" "$SCRIPT_DIR"
fi

build_left() {
    echo "Building left half (Cirque trackpad)..."
    docker run --rm \
        -v "$SCRIPT_DIR:/qmk_userspace" \
        -e QMK_USERSPACE=/qmk_userspace \
        -e SKIP_GIT=1 \
        -e SKIP_VERSION=1 \
        "$IMAGE_NAME" \
        sh -c 'qmk config user.overlay_dir=/qmk_userspace && qmk compile -kb splitkb/halcyon/kyria/rev4 -km obbut -e HLC_CIRQUE_TRACKPAD=1 -e TARGET=kyria_rev4_obbut_left_cirque'
    echo "Build complete: kyria_rev4_obbut_left_cirque.uf2"
}

build_right() {
    echo "Building right half (Encoder)..."
    docker run --rm \
        -v "$SCRIPT_DIR:/qmk_userspace" \
        -e QMK_USERSPACE=/qmk_userspace \
        -e SKIP_GIT=1 \
        -e SKIP_VERSION=1 \
        "$IMAGE_NAME" \
        sh -c 'qmk config user.overlay_dir=/qmk_userspace && qmk compile -kb splitkb/halcyon/kyria/rev4 -km obbut -e HLC_ENCODER=1 -e TARGET=kyria_rev4_obbut_right_encoder'
    echo "Build complete: kyria_rev4_obbut_right_encoder.uf2"
}

case "${1:-all}" in
    left)
        build_left
        ;;
    right)
        build_right
        ;;
    all)
        build_left
        build_right
        ;;
    clean)
        rm -f "$SCRIPT_DIR"/*.uf2 "$SCRIPT_DIR"/*.hex "$SCRIPT_DIR"/*.bin
        echo "Cleaned build artifacts"
        ;;
    rebuild-image)
        docker rmi "$IMAGE_NAME" 2>/dev/null || true
        docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile.qmk" "$SCRIPT_DIR"
        ;;
    *)
        echo "Usage: $0 [left|right|all|clean|rebuild-image]"
        echo ""
        echo "Commands:"
        echo "  left          - Build left half firmware (Cirque trackpad)"
        echo "  right         - Build right half firmware (encoder)"
        echo "  all           - Build both halves (default)"
        echo "  clean         - Remove build artifacts"
        echo "  rebuild-image - Force rebuild the Docker image"
        exit 1
        ;;
esac
