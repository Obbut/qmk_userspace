#!/bin/bash
set -e

cd "$(dirname "$0")"

OUTPUT_DIR="images"
IMAGE_NAME="qmk-keymap-drawer"

mkdir -p "$OUTPUT_DIR"

# Build Docker image if needed
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
  echo "Building Docker image (this may take a few minutes on first run)..."
  docker build -t "$IMAGE_NAME" .
fi

echo "Drawing SVG from keymap.yaml..."
docker run --rm \
  -v "$(pwd):/workdir" \
  -w /workdir \
  "$IMAGE_NAME" \
  keymap -c keymap-drawer.yaml draw keymap.yaml -o "$OUTPUT_DIR/keymap.svg"

echo "Generated $OUTPUT_DIR/keymap.svg"
