#!/usr/bin/env bash
# Exports every Godot project under games/ to dist/<folder>/ for the web,
# and copies the app that holds them (site/) to dist/. Used by CI and for local builds.
#
# Requires: Godot 4 (see .godot-version) with web export templates installed.
# Override the binary with GODOT=/path/to/godot.
set -euo pipefail

cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"

ver="$(git rev-parse --short HEAD 2>/dev/null || date +%s)"

rm -rf dist
mkdir -p dist
cp -r site/. dist/
# The service worker keeps one store of saved files per build, and drops the older ones.
sed "s/__VERSION__/$ver/" site/sw.js > dist/sw.js

entries=()
for project in games/*/project.godot; do
  [ -e "$project" ] || continue
  dir="$(dirname "$project")"
  slug="$(basename "$dir")"
  # A game with a file named .hidden in its folder is left out of the app (the template, for one).
  if [ -e "$dir/.hidden" ]; then
    echo "==> Skipping $slug (hidden)"
    continue
  fi
  name="$(sed -n 's/^config\/name="\(.*\)"$/\1/p' "$project" | head -n1)"
  desc="$(sed -n 's/^config\/description="\(.*\)"$/\1/p' "$project" | head -n1)"

  echo "==> Exporting $slug (${name:-$slug})"
  # Each build lands in its own folder, named after the commit, and <slug>/index.html only forwards
  # to it. A browser that still holds the last build's files can then never mix them with this
  # one: a plain refresh is enough to get the new game.
  mkdir -p "dist/$slug/$ver"
  "$GODOT" --headless --path "$dir" --export-release "Web" "$PWD/dist/$slug/$ver/index.html"
  [ -s "dist/$slug/$ver/index.wasm" ] || { echo "Export failed for $slug" >&2; exit 1; }
  printf '%s\n' '<!doctype html>' '<html lang="he">' '<head>' '<meta charset="utf-8">' \
    "<title>${name:-$slug}</title>" \
    "<meta http-equiv=\"refresh\" content=\"0; url=$ver/\">" \
    "<script>location.replace(\"$ver/\" + location.search + location.hash)</script>" \
    '</head>' "<body><a href=\"$ver/\">${name:-$slug}</a></body>" '</html>' > "dist/$slug/index.html"

  icon=""
  if [ -f "$dir/icon.svg" ]; then
    cp "$dir/icon.svg" "dist/$slug/icon.svg"
    icon="$slug/icon.svg"
  fi

  entries+=("$(printf '{"slug":"%s","name":"%s","description":"%s","path":"%s","icon":"%s"}' \
    "$slug" "${name:-$slug}" "$desc" "$slug/$ver/" "$icon")")
done

(IFS=,; printf '[%s]\n' "${entries[*]:-}") > dist/games.json
echo "==> Built ${#entries[@]} game(s) into dist/"
