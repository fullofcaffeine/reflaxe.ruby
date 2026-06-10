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

## Inventory Rules

Each entry in `docs/stdlib-inventory.json` must include:

- `id`: stable dotted identifier, for example `std.rails.params_macro`.
- `owner`: one of `std`, `std/_std`, or `runtime/hxruby`.
- `status`: `implemented`, `missing`, `planned`, or `deferred`.
- `path`: expected repo path.
- `surface`: user-facing API or runtime surface.
- `reason`: why the surface exists or remains missing.

Use `std/` for additive Ruby/Rails APIs and `std/_std/` for upstream Haxe std overrides that need classpath precedence. Use `runtime/hxruby/` for Ruby files copied or required by generated output.

## Current Gap Summary

As of the current report:

- Total tracked surfaces: `29`
- Implemented: `22`
- Missing: `7`

Remaining gaps are concentrated in general stdlib parity:

- `Array`
- `haxe.Json`
- `Math`
- `Reflect`
- `Type`
- `sys.FileSystem`
- `sys.io.File`

Rails MVP surfaces are tracked as implemented. New Rails or Ruby interop APIs should still get inventory entries so the report stays useful as a release-readiness artifact.
