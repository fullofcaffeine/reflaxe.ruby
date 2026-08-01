#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REFERENCE_ROOT="${HAXE_RUBY_HAXE_REFERENCE:-$ROOT/../haxe.compilerdev.reference/haxe}"

if [[ ! -d "$REFERENCE_ROOT" ]]; then
	cat >&2 <<MSG
Missing exact Haxe source reference: $REFERENCE_ROOT

Set HAXE_RUBY_HAXE_REFERENCE to a Haxe checkout at the pinned manifest commit,
or keep ../haxe.compilerdev.reference/haxe checked out next to this repo.
MSG
	exit 1
fi

# This command is deliberately review-only. It verifies the exact upstream
# commit, every official file/hash, every local fixture/hash, and all adaptation
# patches, then writes a generated report. It never copies or blesses bytes.
node "$ROOT/scripts/ci/unitstd-provenance-check.js" --review --reference "$REFERENCE_ROOT"
