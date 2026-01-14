# QMK Build Script for Windows PowerShell (Docker-based)
# Usage: ./build.ps1 <command>
# Commands: left, right, all, flash-left, flash-right, clean, draw, rebuild-image

param(
    [Parameter(Position=0)]
    [string]$Command = "all"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ImageName = "qmk-userspace-builder"

# Build Docker image if needed
function Ensure-DockerImage {
    $imageExists = docker image inspect $ImageName 2>$null
    if (-not $imageExists) {
        Write-Host "Building QMK Docker image (this takes a few minutes on first run)..."
        docker build -t $ImageName -f "$ScriptDir\Dockerfile.qmk" $ScriptDir
    }
}

function Build-Left {
    Ensure-DockerImage
    Write-Host "Building left half (Cirque trackpad)..."
    docker run --rm `
        -v "${ScriptDir}:/qmk_userspace" `
        -e QMK_USERSPACE=/qmk_userspace `
        -e SKIP_GIT=1 `
        -e SKIP_VERSION=1 `
        $ImageName `
        sh -c 'qmk config user.overlay_dir=/qmk_userspace && qmk compile -kb splitkb/halcyon/kyria/rev4 -km obbut -e HLC_CIRQUE_TRACKPAD=1 -e TARGET=kyria_rev4_obbut_left_cirque'
    Write-Host "Build complete: kyria_rev4_obbut_left_cirque.uf2"
}

function Build-Right {
    Ensure-DockerImage
    Write-Host "Building right half (Encoder)..."
    docker run --rm `
        -v "${ScriptDir}:/qmk_userspace" `
        -e QMK_USERSPACE=/qmk_userspace `
        -e SKIP_GIT=1 `
        -e SKIP_VERSION=1 `
        $ImageName `
        sh -c 'qmk config user.overlay_dir=/qmk_userspace && qmk compile -kb splitkb/halcyon/kyria/rev4 -km obbut -e HLC_ENCODER=1 -e TARGET=kyria_rev4_obbut_right_encoder'
    Write-Host "Build complete: kyria_rev4_obbut_right_encoder.uf2"
}

function Flash-Firmware {
    param([string]$UF2File)

    if (-not (Test-Path "$ScriptDir\$UF2File")) {
        Write-Error "Firmware not found: $UF2File. Run build first."
        return
    }

    Write-Host "Waiting for keyboard bootloader drive..."
    Write-Host "Put the keyboard in bootloader mode (Fn+Esc for left, Fn+' for right)"

    # Wait for RPI-RP2 drive to appear
    $timeout = 60
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        $drives = Get-Volume | Where-Object { $_.FileSystemLabel -eq "RPI-RP2" }
        if ($drives) {
            $driveLetter = ($drives | Select-Object -First 1).DriveLetter
            Write-Host "Found bootloader drive: ${driveLetter}:"
            Copy-Item "$ScriptDir\$UF2File" "${driveLetter}:\"
            Write-Host "Firmware flashed successfully!"
            return
        }
        Start-Sleep -Seconds 1
        $elapsed++
        if ($elapsed % 5 -eq 0) {
            Write-Host "Waiting... ($elapsed seconds)"
        }
    }
    Write-Error "Timeout waiting for bootloader drive"
}

switch ($Command) {
    "left" {
        Build-Left
    }
    "right" {
        Build-Right
    }
    "all" {
        Build-Left
        Build-Right
    }
    "flash-left" {
        Build-Left
        Flash-Firmware "kyria_rev4_obbut_left_cirque.uf2"
    }
    "flash-right" {
        Build-Right
        Flash-Firmware "kyria_rev4_obbut_right_encoder.uf2"
    }
    "clean" {
        Remove-Item -Force "$ScriptDir\*.uf2", "$ScriptDir\*.hex", "$ScriptDir\*.bin" -ErrorAction SilentlyContinue
        Write-Host "Cleaned build artifacts"
    }
    "draw" {
        & "$ScriptDir\draw-keymap.ps1"
    }
    "rebuild-image" {
        docker rmi $ImageName 2>$null
        docker build -t $ImageName -f "$ScriptDir\Dockerfile.qmk" $ScriptDir
    }
    default {
        Write-Host "Usage: ./build.ps1 <command>"
        Write-Host ""
        Write-Host "Commands:"
        Write-Host "  left          - Build left half firmware (Cirque trackpad)"
        Write-Host "  right         - Build right half firmware (encoder)"
        Write-Host "  all           - Build both halves (default)"
        Write-Host "  flash-left    - Build and flash left half"
        Write-Host "  flash-right   - Build and flash right half"
        Write-Host "  clean         - Remove build artifacts"
        Write-Host "  draw          - Generate keymap SVG images"
        Write-Host "  rebuild-image - Force rebuild the Docker image"
        exit 1
    }
}
