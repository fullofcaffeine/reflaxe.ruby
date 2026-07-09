# Gap Report Guidance

The gap report tracks std/runtime surfaces that are implemented, missing, planned, or deferred for the Ruby target.

## Files

- Source inventory: `docs/stdlib-inventory.json`
- Generated report: `test/ruby_gap_report.json`
- Checker: `scripts/ci/gap-report-check.js`

## Commands

Validate the committed report:

```bash
npm run test:gap-report
```

Regenerate after inventory changes:

```bash
UPDATE_GAP_REPORT=1 npm run test:gap-report
```

Validate that committed std/runtime files are represented:

```bash
npm run test:stdlib-inventory
```

Run upstream Haxe std runtime fixtures selected for Ruby:

```bash
npm run test:unitstd-ruby
```

## Inventory Rules

Each entry in `docs/stdlib-inventory.json` must include:

- `id`: stable dotted identifier, for example `std.rails.params_macro`.
- `owner`: one of `std`, `std/ruby/_std`, or `runtime/hxruby`.
- `status`: `implemented`, `missing`, `planned`, or `deferred`.
- `path`: expected repo path.
- `surface`: user-facing API or runtime surface.
- `reason`: why the surface exists or remains missing.

Use `std/` for additive Ruby/Rails APIs and `std/ruby/_std/` for upstream Haxe
std overrides that need classpath precedence in source checkouts. Reflaxe build
packages those `_std` files as `src/**/*.cross.hx`. Use `runtime/hxruby/` for
Ruby files copied or required by generated output.

When changing a std/runtime surface that has a matching upstream Haxe
`unitstd` fixture, update `test/upstream_unitstd/manifest.json` in the same
change. Prefer enabling the fixture once it passes. If the Ruby target needs a
runtime helper to preserve Haxe semantics, keep it in `runtime/hxruby` and add
or update inventory/gap-report entries as appropriate; do not silently patch
Ruby core classes or leave the fixture untracked.

## Current Gap Summary

As of the current report:

- Total tracked surfaces: `202`
- Implemented: `202`
- Missing: `0`

The report is currently green with no missing tracked std/runtime surfaces. New
Rails, Ruby interop, Haxe std override, or runtime APIs should still get
inventory entries so the report stays useful as a release-readiness artifact.
When upstream Haxe has a matching `unitstd` fixture, update
`test/upstream_unitstd/manifest.json` at the same time so runtime parity and
inventory coverage do not drift.
