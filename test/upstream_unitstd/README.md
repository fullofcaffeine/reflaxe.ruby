# Upstream Haxe `unitstd` Runtime Specs

This directory contains a curated, checked-in subset of Haxe upstream
`tests/unit/src/unitstd/**/*.unit.hx` specs for the Ruby target.

Why this exists:

- Snapshot tests validate generated Ruby shape.
- These specs validate Ruby runtime behavior against Haxe's stdlib contract.
- CI must be deterministic, so it cannot depend on a sibling Haxe checkout.

Source provenance:

- Upstream source: Haxe `tests/unit/src/unitstd`
- Haxe standard library/tests are distributed under the Haxe Foundation MIT
  license; see the upstream `extra/LICENSE.txt`.

Coverage policy:

- `manifest.json` tracks high-leverage stdlib surfaces and whether an upstream
  fixture is enabled, adapted, skipped for Ruby triage, unsupported, or absent.
- Enabled fixtures compile through haxe.ruby and run as plain Ruby via
  `npm run test:unitstd-ruby`.
- Non-enabled entries must explain whether no upstream spec exists, the spec is
  unsupported for this target, or target-specific triage is still required.

Current upstream runtime fixtures:

- Enabled: `IntIterator`, `String`, `StringBuf`, `StringTools`,
  `haxe.io.BytesBuffer`.

The first lane is intentionally narrow. It proves the harness, provenance, sync
workflow, and runtime execution shape without pretending broad Ruby stdlib parity
is already complete. Expand the lane fixture-by-fixture as Ruby std support
hardens.

Use `scripts/sync-upstream-unitstd-specs.sh` to refresh enabled, unadapted specs
from a local Haxe reference checkout. The sync normalizes fixture whitespace
with the repo Haxe formatter so normal formatting gates stay green. Adapted
specs must be reviewed manually so their local target changes are not
overwritten.
