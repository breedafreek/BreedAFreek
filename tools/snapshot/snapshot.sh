#!/usr/bin/env bash
# Renders Freeks to PNGs. Usage: tools/snapshot/snapshot.sh <outDir> [speciesId[:Mutation] ...]
# Weapons: tools/snapshot/snapshot.sh <outDir> --weapons [weaponId ...]
# Build once first: (cd tools/snapshot && cargo build --release && npm install)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
out="$1"; shift
mkdir -p "$out"
"$here/target/release/freek-snapshot" "$here/harness.luau" "$here/../../src/shared" "$@" > "$out/freeks.json"
node "$here/render.mjs" "$out/freeks.json" "$out"
