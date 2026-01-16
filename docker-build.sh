#!/bin/bash
# Docker-based QMK build script
# Works on any platform with Docker installed

set -e

# Disable MINGW path conversion for Docker volume mounts on Windows
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="qmk-userspace-builder"
KEYCHRON_IMAGE_NAME="qmk-keychron-builder"
BUILD_CACHE="$SCRIPT_DIR/.docker-build-cache"
KEYCHRON_BUILD_CACHE="$SCRIPT_DIR/.docker-build-cache-keychron"

# Create build cache directories
mkdir -p "$BUILD_CACHE"
mkdir -p "$KEYCHRON_BUILD_CACHE"

# Build mainline QMK Docker image if needed
build_qmk_image() {
    if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
        echo "Building QMK Docker image (this takes a few minutes on first run)..."
        docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile.qmk" "$SCRIPT_DIR"
    fi
}

# Build Keychron QMK Docker image if needed
build_keychron_image() {
    if ! docker image inspect "$KEYCHRON_IMAGE_NAME" &>/dev/null; then
        echo "Building Keychron QMK Docker image (this takes a few minutes on first run)..."
        docker build -t "$KEYCHRON_IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile.keychron" "$SCRIPT_DIR"
    fi
}

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
        drive=$(find_bootloader_drive || true)
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

# Check if STM32 DFU device is present (for Q15 Max)
check_dfu_device() {
    if command -v powershell.exe &>/dev/null; then
        # Windows: Check for STM32 DFU device via PowerShell
        local result
        result=$(powershell.exe -NoProfile -Command '
            $device = Get-PnpDevice -Status OK 2>$null | Where-Object { $_.InstanceId -match "VID_0483&PID_DF11" }
            if ($device) { "found" } else { "not_found" }
        ' 2>/dev/null | tr -d '\r\n')
        [[ "$result" == "found" ]]
    elif command -v dfu-util &>/dev/null; then
        # macOS/Linux: Check via dfu-util (more reliable than lsusb)
        dfu-util --list 2>/dev/null | grep -q "0483:df11"
    elif command -v lsusb &>/dev/null; then
        # Linux fallback: Check via lsusb
        lsusb -d 0483:df11 &>/dev/null
    else
        return 1
    fi
}

# Flash Q15 Max via DFU
flash_q15_dfu() {
    local bin_file="$1"

    if [[ ! -f "$SCRIPT_DIR/$bin_file" ]]; then
        echo "Error: Firmware file not found: $bin_file"
        echo "Run build first."
        exit 1
    fi

    echo ""
    echo "Waiting for Q15 Max in DFU mode..."
    echo "To enter DFU mode: Press Fn + Tab"
    echo "(Or hold Tab while plugging in USB)"
    echo ""

    local timeout=60
    local elapsed=0

    while [[ $elapsed -lt $timeout ]]; do
        if check_dfu_device; then
            echo "Found STM32 DFU device!"
            echo "Flashing $bin_file..."

            if command -v dfu-util &>/dev/null; then
                dfu-util -a 0 -d 0483:df11 -s 0x08000000:leave -D "$SCRIPT_DIR/$bin_file"
                echo "Firmware flashed successfully!"
                return 0
            elif command -v dfu-util.exe &>/dev/null; then
                dfu-util.exe -a 0 -d 0483:df11 -s 0x08000000:leave -D "$SCRIPT_DIR/$bin_file"
                echo "Firmware flashed successfully!"
                return 0
            else
                echo "Error: dfu-util not found."
                echo "Please install dfu-util and add it to your PATH."
                echo "Download from: https://dfu-util.sourceforge.net/releases/"
                echo "Or install QMK MSYS which includes dfu-util."
                exit 1
            fi
        fi
        sleep 1
        elapsed=$((elapsed + 1))
        if [[ $((elapsed % 5)) -eq 0 ]]; then
            echo "Waiting... ($elapsed seconds)"
        fi
    done

    echo "Error: Timeout waiting for DFU device"
    exit 1
}

build_left() {
    build_qmk_image
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
    build_qmk_image
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

build_q15() {
    build_keychron_image
    echo "Building Keychron Q15 Max..."
    docker run --rm \
        -v "$SCRIPT_DIR:/qmk_userspace" \
        -v "$KEYCHRON_BUILD_CACHE:/qmk_firmware/.build" \
        "$KEYCHRON_IMAGE_NAME" \
        sh -c 'export QMK_USERSPACE=/qmk_userspace && cd /qmk_firmware && make keychron/q15_max/ansi_encoder:obbut'
    echo "Build complete: keychron_q15_max_ansi_encoder_obbut.bin"
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
    q15)
        build_q15
        ;;
    flash-q15)
        build_q15
        flash_q15_dfu "keychron_q15_max_ansi_encoder_obbut.bin"
        ;;
    clean)
        rm -f "$SCRIPT_DIR"/*.uf2 "$SCRIPT_DIR"/*.hex "$SCRIPT_DIR"/*.bin
        echo "Cleaned build artifacts"
        ;;
    rebuild-image)
        echo "Rebuilding QMK Docker image..."
        docker rmi "$IMAGE_NAME" 2>/dev/null || true
        docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile.qmk" "$SCRIPT_DIR"
        ;;
    rebuild-keychron-image)
        echo "Rebuilding Keychron QMK Docker image..."
        docker rmi "$KEYCHRON_IMAGE_NAME" 2>/dev/null || true
        docker build -t "$KEYCHRON_IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile.keychron" "$SCRIPT_DIR"
        ;;
    *)
        echo "Usage: $0 [command]"
        echo ""
        echo "Kyria (Halcyon) commands:"
        echo "  left             - Build left half firmware (Cirque trackpad)"
        echo "  right            - Build right half firmware (encoder)"
        echo "  all              - Build both Kyria halves (default)"
        echo "  flash-left       - Build and flash left half"
        echo "  flash-right      - Build and flash right half"
        echo ""
        echo "Keychron Q15 Max commands:"
        echo "  q15              - Build Q15 Max firmware"
        echo "  flash-q15        - Build and flash Q15 Max (requires dfu-util)"
        echo ""
        echo "Maintenance:"
        echo "  clean            - Remove build artifacts"
        echo "  rebuild-image    - Force rebuild the QMK Docker image"
        echo "  rebuild-keychron-image - Force rebuild the Keychron Docker image"
        exit 1
        ;;
esac
