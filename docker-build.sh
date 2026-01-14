#!/bin/bash
# Docker-based QMK build script
# Works on any platform with Docker installed

set -e

# Disable MINGW path conversion for Docker volume mounts on Windows
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="qmk-userspace-builder"
BUILD_CACHE="$SCRIPT_DIR/.docker-build-cache"

# Create build cache directory
mkdir -p "$BUILD_CACHE"

# Build Docker image if needed
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo "Building QMK Docker image (this takes a few minutes on first run)..."
    docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile.qmk" "$SCRIPT_DIR"
fi

# Find the RPI-RP2 bootloader drive (cross-platform)
find_bootloader_drive() {
    # macOS
    if [[ -d "/Volumes/RPI-RP2" ]]; then
        echo "/Volumes/RPI-RP2"
        return 0
    fi

    # Linux (common mount points)
    for base in "/media/$USER" "/run/media/$USER" "/mnt"; do
        if [[ -d "$base/RPI-RP2" ]]; then
            echo "$base/RPI-RP2"
            return 0
        fi
    done

    # Windows (Git Bash/MSYS) - use PowerShell to find drive letter
    if command -v powershell.exe &>/dev/null; then
        local drive
        # Use a script block to avoid bash escaping issues with $_
        drive=$(powershell.exe -NoProfile -Command 'Get-Volume | Where-Object FileSystemLabel -eq "RPI-RP2" | Select-Object -ExpandProperty DriveLetter' 2>/dev/null | tr -d '\r\n')
        if [[ -n "$drive" ]]; then
            echo "/$(echo "$drive" | tr '[:upper:]' '[:lower:]')"
            return 0
        fi
    fi

    return 1
}

# Wait for bootloader drive and flash firmware
flash_firmware() {
    local uf2_file="$1"
    local side="$2"

    if [[ ! -f "$SCRIPT_DIR/$uf2_file" ]]; then
        echo "Error: Firmware file not found: $uf2_file"
        echo "Run build first."
        exit 1
    fi

    echo ""
    echo "Waiting for bootloader drive..."
    if [[ "$side" == "left" ]]; then
        echo "Put the LEFT half in bootloader mode: Fn + Esc"
    else
        echo "Put the RIGHT half in bootloader mode: Fn + '"
    fi
    echo ""

    local timeout=60
    local elapsed=0
    local drive=""

    while [[ $elapsed -lt $timeout ]]; do
        drive=$(find_bootloader_drive)
        if [[ -n "$drive" ]]; then
            echo "Found bootloader drive: $drive"
            echo "Copying $uf2_file..."
            cp "$SCRIPT_DIR/$uf2_file" "$drive/"
            echo "Firmware flashed successfully!"
            return 0
        fi
        sleep 1
        elapsed=$((elapsed + 1))
        if [[ $((elapsed % 5)) -eq 0 ]]; then
            echo "Waiting... ($elapsed seconds)"
        fi
    done

    echo "Error: Timeout waiting for bootloader drive"
    exit 1
}

build_left() {
    echo "Building left half (Cirque trackpad)..."
    docker run --rm \
        -v "$SCRIPT_DIR:/qmk_userspace" \
        -v "$BUILD_CACHE:/qmk_firmware/.build" \
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
        -v "$BUILD_CACHE:/qmk_firmware/.build" \
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
    flash-left)
        build_left
        flash_firmware "kyria_rev4_obbut_left_cirque.uf2" "left"
        ;;
    flash-right)
        build_right
        flash_firmware "kyria_rev4_obbut_right_encoder.uf2" "right"
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
        echo "Usage: $0 [left|right|all|flash-left|flash-right|clean|rebuild-image]"
        echo ""
        echo "Commands:"
        echo "  left          - Build left half firmware (Cirque trackpad)"
        echo "  right         - Build right half firmware (encoder)"
        echo "  all           - Build both halves (default)"
        echo "  flash-left    - Build and flash left half"
        echo "  flash-right   - Build and flash right half"
        echo "  clean         - Remove build artifacts"
        echo "  rebuild-image - Force rebuild the Docker image"
        exit 1
        ;;
esac
