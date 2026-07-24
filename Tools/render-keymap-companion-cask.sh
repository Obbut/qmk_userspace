#!/usr/bin/env bash

set -euo pipefail

if (( $# != 3 )); then
    echo "Usage: $0 <version> <sha256> <output-path>" >&2
    exit 64
fi

version="$1"
sha256="$2"
output_path="$3"

if [[ ! "$version" =~ ^(0|[1-9][0-9]*)\.((0|[1-9][0-9]*))\.((0|[1-9][0-9]*))$ ]]; then
    echo "Invalid semantic version: $version" >&2
    exit 65
fi

if [[ ! "$sha256" =~ ^[0-9a-f]{64}$ ]]; then
    echo "Invalid SHA-256: $sha256" >&2
    exit 65
fi

mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<CASK
# typed: strict
# frozen_string_literal: true

cask "keymap-companion" do
  version "$version"
  sha256 "$sha256"

  url "https://github.com/Obbut/qmk_userspace/releases/download/keymap-companion-v#{version}/KeymapCompanion-#{version}-macos-arm64.zip",
      verified: "github.com/Obbut/qmk_userspace/"
  name "Keymap Companion"
  desc "Menu bar companion for viewing and controlling Obbut QMK keyboards"
  homepage "https://github.com/Obbut/qmk_userspace"

  livecheck do
    url :url
    regex(/^keymap-companion-v(\d+(?:\.\d+)+)$/i)
    strategy :github_releases
  end

  depends_on arch: :arm64
  depends_on macos: ">= :tahoe"

  app "KeymapCompanion.app"

  zap trash: [
    "~/Library/Application Support/Obbut/KeymapCompanion",
    "~/Library/Preferences/com.obbut.KeymapCompanion.plist",
  ]
end
CASK
