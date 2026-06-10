# Compatibility Matrix

This document records the supported tool/runtime contract for `reflaxe.ruby`.

## CI Baseline

| Surface | Versions | Status | Notes |
| --- | --- | --- | --- |
| Haxe | `4.3.7` | Supported | Pinned by `.haxerc` and `.github/workflows/ci.yml`. |
| Node.js | `20` | Supported | Used for CI scripts, generators, and semantic-release. |
| Ruby | `3.2`, `3.3`, `4.0` | Supported | CI matrix validates runtime smoke tests against these versions. |
| Rails | Rails 7+/8 style app shape | Compile/syntax covered | Runtime Rails tests run when Rails gems are available; set `REQUIRE_RAILS=1` to make them mandatory. |

## Local Development Notes

Some lightweight Ruby smoke tests can pass on older system Rubies, including Ruby `2.6`, but that is a convenience only. Rails-first output assumes modern Ruby and Rails baselines from the PRD.

The runtime file `runtime/hxruby/data_define.rb` includes compatibility behavior for older Rubies that do not provide `Data.define`; this is why Ruby `2.6` may emit `Data` deprecation warnings in local minitest output. Those warnings are expected locally and are not part of the supported Rails baseline.

## Profiles

| Profile | Define | Status | Purpose |
| --- | --- | --- | --- |
| Idiomatic | `-D reflaxe_ruby_profile=idiomatic` | Default | Prefer Ruby naming, kwargs, blocks, and minimal runtime helpers. |
| Portable | `-D reflaxe_ruby_profile=portable` | Available | Reserved for closer Haxe semantics where Ruby idioms would drift behavior. |

## Rails Mode

| Feature | Define/tool | Status |
| --- | --- | --- |
| Rails output root | `-D reflaxe_ruby_rails` | Implemented |
| Custom Rails output root | `-D reflaxe_ruby_rails_output_root=<path>` | Implemented |
| ActiveRecord model surface | `rails.active_record.Base<T>` | Implemented |
| Associations/validations metadata | `@:belongsTo`, `@:hasMany`, `@:hasOne`, `@:validates` | Implemented |
| ActionController surface | `rails.action_controller.Base` | Implemented |
| Strong params macro | `ParamsMacro.requirePermit(...)` | Implemented |
| Route helper generator | `npm run rails:generate-routes` | Implemented |
| Scaffold generator | `npm run rails:scaffold` | Implemented |

## Strict Boundary Policy

| Define | Status | Behavior |
| --- | --- | --- |
| `reflaxe_ruby_strict_examples` | Implemented | Rejects raw `__ruby__` injection in examples and tests/snapshots. |
| `reflaxe_ruby_strict` | Implemented | Rejects raw `__ruby__` injection in project sources. |
| `@:rubyAllowRaw` | Implemented | Narrow module/type escape hatch for policy-specific tests or framework-owned islands. |
