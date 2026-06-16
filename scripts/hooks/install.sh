#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"

chmod +x "$ROOT_DIR/scripts/hooks/pre-commit"
git config core.hooksPath scripts/hooks

echo "[hooks] Installed repo hooks from scripts/hooks."
echo "[hooks] Requirements: gitleaks and haxelib formatter."
echo "[hooks] Install formatter with: haxelib install formatter"
