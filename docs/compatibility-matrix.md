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
| Ruby-first | `-D reflaxe_ruby_profile=ruby_first` | Default | Ruby/Rails conventions win when they conflict with cross-target portability. |
| Portable | `-D reflaxe_ruby_profile=portable` | Available | Haxe-semantics-first contract. Still emit idiomatic Ruby where behavior is preserved. |

See [Ruby Profiles](profiles.md) for the full profile contract. `-D reflaxe_ruby_profile=idiomatic` and `-D ruby_idiomatic` remain compatibility aliases for `ruby_first`. Profiles are semantic guardrails in one compiler pipeline, not separate backends. `metal` is intentionally not a public Ruby profile; performance policy should use explicit optimizer/runtime defines instead.

## Rails Mode

| Feature | Define/tool | Status |
| --- | --- | --- |
| Rails output root | `-D reflaxe_ruby_rails` | Implemented |
| Custom Rails output root | `-D reflaxe_ruby_rails_output_root=<path>` | Implemented |
| ActiveRecord model surface | `rails.active_record.Base<T>` | Implemented |
| ActiveRecord schema registry | `Todo.__hx_rails_schema` | Implemented |
| Associations/validations metadata | `@:belongsTo`, `@:hasMany`, `@:hasOne`, `@:validates` | Implemented |
| ActionController surface | `rails.action_controller.Base` | Implemented |
| Strong params macro | `ParamsMacro.requirePermit(...)` | Implemented |
| Typed ActionView render locals | `ViewMacro.renderTemplate(...)` + `Template<TLocals>` | Implemented |
| Rails template artifact generation | `@:railsTemplate(...)` | Implemented |
| Typed ActionView template AST | `@:railsTemplateAst(...)` + `H`/`HtmlNode`/`HtmlAttr` | Initial partial/component slice |
| Raw ERB template escape hatch | `@:railsAllowRawErb` | Implemented |
| Route helper generator | `npm run rails:generate-routes` | Implemented |
| Scaffold generator | `npm run rails:scaffold` | Implemented |

The rows above describe the current Rails MVP. The deeper typed Rails compiler layer is tracked as RailsHx; see `docs/railshx-roadmap.md` and the `haxe.ruby-wpi` bead epic.

## Strict Boundary Policy

| Define | Status | Behavior |
| --- | --- | --- |
| `reflaxe_ruby_strict_examples` | Implemented | Rejects raw `__ruby__` injection in examples and tests/snapshots. |
| `reflaxe_ruby_strict` | Implemented | Rejects raw `__ruby__` injection in project sources. |
| `@:rubyAllowRaw` | Implemented | Narrow module/type escape hatch for policy-specific tests or framework-owned islands. |
