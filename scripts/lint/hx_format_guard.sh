#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
MODE="check"

if [ "${1:-}" = "--write" ]; then
  MODE="write"
fi

if ! command -v haxelib >/dev/null 2>&1; then
  echo "[guard:hx-format] ERROR: haxelib is required." >&2
  exit 1
fi

if ! haxelib run formatter --help >/dev/null 2>&1; then
  echo "[guard:hx-format] ERROR: formatter haxelib is not installed." >&2
  echo "[guard:hx-format] Install it with: haxelib install formatter" >&2
  exit 1
fi

sources=()
for source in src std examples; do
  if [ -d "$ROOT_DIR/$source" ]; then
    sources+=("-s" "$ROOT_DIR/$source")
  fi
done

while IFS= read -r test_source; do
  sources+=("-s" "$test_source")
done < <(find "$ROOT_DIR/test" -name '*.hx' -not -path "$ROOT_DIR/test/.generated/*" | sort)

if [ "${#sources[@]}" -eq 0 ]; then
  echo "[guard:hx-format] OK: no Haxe sources found."
  exit 0
fi

if [ "$MODE" = "write" ]; then
  echo "[guard:hx-format] Formatting Haxe sources..."
  haxelib run formatter "${sources[@]}"
else
  echo "[guard:hx-format] Checking Haxe formatting..."
  haxelib run formatter "${sources[@]}" --check
fi

echo "[guard:hx-format] OK"
