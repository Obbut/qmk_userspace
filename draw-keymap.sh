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

# Layer names (must match keymap.yaml)
LAYERS=("Default" "Lower" "Raise" "Function")

# Draw each layer separately
for layer in "${LAYERS[@]}"; do
  lowercase=$(echo "$layer" | tr '[:upper:]' '[:lower:]')
  echo "Drawing $layer layer..."
  docker run --rm \
    -v "$(pwd):/workdir" \
    -w /workdir \
    "$IMAGE_NAME" \
    keymap -c keymap-drawer.yaml draw keymap.yaml -s "$layer" -o "$OUTPUT_DIR/keymap-$lowercase.svg"
done

echo "Generated layer images in $OUTPUT_DIR/"
