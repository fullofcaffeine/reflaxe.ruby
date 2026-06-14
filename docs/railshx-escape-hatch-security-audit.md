# RailsHx Escape Hatch And Security Audit

This audit names every production-relevant unsafe boundary currently allowed by
RailsHx and records how it is controlled. The goal is not to ban all Ruby/Rails
escape hatches; the goal is to make them explicit, searchable, opt-in, and
replaceable with typed APIs over time.

Tracking gate: `haxe.ruby-bjv.4`.

## Policy

- Default app-facing RailsHx code should use typed APIs, generated refs, macros,
  HHX, typed externs, and Rails-native generated output.
- Escape hatches must be named like escape hatches: `raw`, `external`,
  `existing`, `unchecked`, or a similarly explicit term.
- Checked escapes are preferred over unchecked escapes. For example,
  `Template.existing("legacy/badge") : Template<TLocals>` checks filesystem
  presence, while `Template.external("legacy/badge")` is lower-level.
- File-backed macros and generators fail closed by default. Missing templates,
  RBS files, Ruby source files, route dumps, or extension sources are errors
  unless the API name explicitly says the source is external/unchecked.
- LLM assistance is advisory only. It may suggest typed contracts, but cannot
  bypass generator validation, Haxe compilation, Ruby syntax checks, Rails
  runtime gates, or human review.
- Canonical RailsHx examples, especially `examples/todoapp_rails`, must avoid
  raw Ruby, raw ERB, unchecked paths, and casual `Dynamic` when a typed RailsHx
  API exists.

## Follow-Up Beads

| Bead | Priority | Scope | Required outcome |
| --- | --- | --- | --- |
| `haxe.ruby-bjv.4.1` | P1 | SQL/string escapes | Enforce the SQL/string policy across ActiveRecord, migrations, templates, Turbo, and related Rails APIs. |
| `haxe.ruby-bjv.4.2` | P1 | `Dynamic` boundaries | Classify and replace app-facing `Dynamic` uses with typed facades, abstracts, or generated contracts where possible. |
| `haxe.ruby-bjv.4.3` | P1 | Template/path escapes | Harden `Template.named`, `Template.external`, `@:railsTemplate(...)` paths, and filesystem checks. |
| `haxe.ruby-bjv.4.4` | P1 | Generator/LLM inference | Keep adoption inference deterministic, fail-closed, reviewable, and non-executing. |

## Escape Hatch Inventory

| Boundary | Default | Escape hatch | Current enforcement | Tests/docs | Follow-up |
| --- | --- | --- | --- | --- | --- |
| Raw Ruby injection | Typed std/runtime wrappers, externs, macros, or generated RailsHx APIs. | `untyped __ruby__(...)` inside narrowly scoped `@:rubyAllowRaw` modules/types. | `reflaxe_ruby_strict_examples` rejects raw injection in examples/tests; `reflaxe_ruby_strict` rejects project-source raw injection; raw call first argument must be a constant string. | `npm run test:strict-boundaries`; README strict policy; AGENTS rule forbids app-level raw Ruby. | Keep as-is for std/runtime internals; use `haxe.ruby-bjv.4.2` for app-facing dynamic/raw replacements. |
| Raw ERB authoring | HHX through `@:railsTemplateAst(...)`, typed `HtmlNode`, typed locals, and compiler-emitted ERB. | `@:railsAllowRawErb` on `@:railsTemplate(...)` classes. | Compiler rejects raw ERB bodies unless the explicit metadata is present. Canonical todoapp smoke rejects `@:railsAllowRawErb` in todoapp source. | `npm run test:todoapp-rails`; AGENTS hard rule for HHX default. | `haxe.ruby-bjv.4.3`, `haxe.ruby-bjv.3.4` for broader HHX helper coverage. |
| Existing Rails ERB | Haxe-owned templates use `Template.of(...)`/`Template.layout(...)`; external Rails-owned ERB uses checked contracts. | `Template.existing("path") : Template<TLocals>` for checked Rails-owned ERB; `Template.external("path")` when a synthetic/test fixture cannot be discovered. | `Template.existing` requires a string literal, validates safe path shape, and checks `app/views`/`rails/app/views`. `Template.external` remains typed for locals but does not check filesystem presence. | `npm run test:rails-interop`; `npm run test:rails-adopt-generator`; gradual adoption docs. | `haxe.ruby-bjv.4.3` for more complete path/unchecked policy. |
| Rails template path strings | Typed template refs: `Template.of(ViewClass)` and `Template.layout(LayoutViewClass)`. | `@:railsTemplate("...")`, `Template.named("...")`, and `Template.external("...")`. | Literal-only and path-shape checks exist for compiler-owned paths; missing Haxe-owned view classes fail through typed refs. | `npm run test:todoapp-rails`; type-safety review. | `haxe.ruby-bjv.4.3`. |
| SQL/string-bearing query APIs | Typed refs/builders such as `Todo.f.title`, criteria objects, `Order.many`, `Projection.pluck`, `Group.count`. | Future raw SQL/string APIs must be explicit and auditable; current policy forbids casual addition. | The production API gap audit classifies this as a P1 blocker before adding broader SQL-bearing APIs. | `docs/railshx-typed-api-production-gap-audit.md`. | `haxe.ruby-bjv.4.1`, `haxe.ruby-bjv.3.7`. |
| Migration unknown tables | `models`/`knownModels` registry validates tables, columns, indexes, and foreign keys. | `externalTables: ["legacy_events"]` for Rails-owned schema outside Haxe metadata. | Unknown known-model tables/columns fail closed; external tables intentionally skip column validation. | `npm run test:todoapp-rails`; migration comments in todoapp README. | `haxe.ruby-bjv.4.1`, `haxe.ruby-bjv.3.2`. |
| Generator/adoption source files | Deterministic metadata from Rails source, RBS, routes, schemas, or typed Haxe metadata. | Suggest-only discovery and future LLM-assisted patches. | Missing source/RBS files fail closed; generators protect existing wrappers; discovery prints suggestions without writing guessed contracts. | `npm run test:rails-adopt-generator`; gradual adoption and Ruby extension docs. | `haxe.ruby-bjv.4.4`, `haxe.ruby-bjv.6`. |
| `Dynamic` in app-facing APIs | Typed facades, generated externs, abstracts, and typed payload/locals/contracts. | `Dynamic` only at real runtime interop boundaries or generated review placeholders. | Some surfaces still use `Dynamic`: route params, JS/Turbo event details, ActionCable consumers, ActiveSupport subscription handles, generator-inferred unknown types. This is documented as a hardening target. | Compatibility matrix, controller/Turbo/generator docs. | `haxe.ruby-bjv.4.2`. |
| Behavior-bearing DOM hooks and CSS strings | Typed constants/abstracts shared by HHX, Haxe JS, and Playwright. | Local styling-only class strings. | Todoapp centralizes IDs/selectors/data attrs/storage keys through `shared.TodoHooks` and exports them to Playwright. | `npm run test:todoapp-rails`; `npm run test:todoapp-playwright`. | `haxe.ruby-bjv.3.4`, `haxe.ruby-bjv.3.6` for broader component/Turbo coverage. |

## Required Gates

Run these when changing escape-hatch behavior:

```bash
npm run test:strict-boundaries
npm run test:todoapp-rails
npm run test:rails-interop
npm run test:rails-adopt-generator
npm run test:rails-generators
npm run ci:release-contracts
```

Use `npm run test:rails-runtime` and `npm run test:todoapp-production` when the
escape touches Rails runtime behavior, generated Rails app shape, migrations,
autoloading, or production assets.

## Current Decision

RailsHx production readiness remains blocked on the follow-up beads above, but
the escape hatches are now named and auditable. New RailsHx work should not add
another unsafe boundary unless this document is updated, a bead is filed, and
the API name makes the risk obvious.
