#!/usr/bin/env bash
# Exports every Godot project under games/ to dist/<folder>/ for the web,
# and copies the landing page to dist/. Used by CI and for local builds.
#
# Requires: Godot 4 (see .godot-version) with web export templates installed.
# Override the binary with GODOT=/path/to/godot.
set -euo pipefail

cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"

rm -rf dist
mkdir -p dist
cp -r site/. dist/

entries=()
for project in games/*/project.godot; do
  [ -e "$project" ] || continue
  dir="$(dirname "$project")"
  slug="$(basename "$dir")"
  name="$(sed -n 's/^config\/name="\(.*\)"$/\1/p' "$project" | head -n1)"
  desc="$(sed -n 's/^config\/description="\(.*\)"$/\1/p' "$project" | head -n1)"

  echo "==> Exporting $slug (${name:-$slug})"
  mkdir -p "dist/$slug"
  "$GODOT" --headless --path "$dir" --export-release "Web" "$PWD/dist/$slug/index.html"
  [ -s "dist/$slug/index.wasm" ] || { echo "Export failed for $slug" >&2; exit 1; }

  entries+=("$(printf '{"slug":"%s","name":"%s","description":"%s"}' "$slug" "${name:-$slug}" "$desc")")
done

(IFS=,; printf '[%s]\n' "${entries[*]:-}") > dist/games.json
echo "==> Built ${#entries[@]} game(s) into dist/"
