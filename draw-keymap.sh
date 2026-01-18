#!/bin/bash
set -e

# Disable MINGW path conversion for Docker volume mounts on Windows
export MSYS_NO_PATHCONV=1

cd "$(dirname "$0")"

OUTPUT_DIR="images"
IMAGE_NAME="qmk-keymap-drawer"

mkdir -p "$OUTPUT_DIR"

# Build Docker image if needed
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
  echo "Building Docker image (this may take a few minutes on first run)..."
  docker build -t "$IMAGE_NAME" .
fi

# Draw a keymap
# Usage: draw_keymap <yaml_file> <output_prefix> <layer1> [layer2] ...
draw_keymap() {
  local yaml_file="$1"
  local output_prefix="$2"
  shift 2
  local layers=("$@")

  echo "Drawing $yaml_file..."
  for layer in "${layers[@]}"; do
    lowercase=$(echo "$layer" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    echo "  - $layer layer..."
    docker run --rm \
      -v "$(pwd):/workdir" \
      -w /workdir \
      "$IMAGE_NAME" \
      keymap -c keymap-drawer.yaml draw "$yaml_file" -s "$layer" -o "$OUTPUT_DIR/$output_prefix-$lowercase.svg"
  done
}

# Kyria layers
draw_keymap "keymap-kyria.yaml" "kyria" "Default" "Lower" "Raise" "Function"

# Q15 Max layers
draw_keymap "keymap-q15.yaml" "q15" "Mac Base" "Win Base" "Mac Fn1" "Win Fn1" "Fn2" "Raise"

echo ""
echo "Generated layer images in $OUTPUT_DIR/"
ls -la "$OUTPUT_DIR"/*.svg 2>/dev/null || true
