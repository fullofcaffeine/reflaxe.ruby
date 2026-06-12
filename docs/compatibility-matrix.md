# Compatibility Matrix

This document records the supported tool/runtime contract for `reflaxe.ruby`.

## CI Baseline

| Surface | Versions | Status | Notes |
| --- | --- | --- | --- |
| Haxe | `4.3.7` | Supported | Pinned by `.haxerc` and `.github/workflows/ci.yml`. |
| Node.js | `20` | Supported | Used for CI scripts, release tooling, and repository sample materializers. Rails-facing generators are Ruby-native. |
| Ruby | `3.2`, `3.3`, `4.0` | Supported | CI matrix validates runtime smoke tests against these versions. |
| Rails | Rails 7+/8 style app shape | Compile/syntax and runtime covered | `npm test` keeps local runtime checks optional when generated app bundles are missing; `npm run test:rails-runtime` and CI make Rails integration/interop runtime execution mandatory. |

## Local Development Notes

The repo pins local Ruby with `.ruby-version`; `rbenv install` from the repo root installs the currently recommended local lane. Use Ruby `3.3.x` for day-to-day development because it matches the middle CI lane while keeping Rails and gem-package checks on the supported baseline.

Some lightweight Ruby smoke tests can pass on older system Rubies, including Ruby `2.6`, but that is a convenience only. Rails-first output assumes modern Ruby and Rails baselines from the PRD.

The runtime file `runtime/hxruby/data_define.rb` includes compatibility behavior for older Rubies that do not provide `Data.define`; this is why Ruby `2.6` may emit `Data` deprecation warnings in local minitest output. Those warnings are expected locally and are not part of the supported Rails baseline.

Run `npm run test:rails-runtime` from the pinned Ruby to install generated app bundles and execute the mandatory Rails runtime integration and mixed-interop tests locally. The plain `npm test` command remains friendly for fast compiler work: it syntax-checks generated Rails artifacts and runs Rails runtime tests only when the local bundles are already available.

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
| Typed ActiveRecord field refs | `Todo.fields.title` / `Todo.f.title : Field<Todo, String>`, `Todo.railsParamKey : ModelKey<Todo>` | Initial form/params slice |
| Typed ActiveRecord association refs | `Todo.associations.user` / `Todo.a.user : Association<Todo, User>` | Initial association query slice |
| Typed ActiveRecord relation chain | `Todo.where({completed: false}).where(...).order(Todo.f.title.asc()).limit(10) : Relation<Todo, criteria>` inferred | Initial query slice |
| Typed ActiveRecord association queries | `Todo.includes(Todo.associations.user).joins(Todo.a.user)` | Initial association query slice |
| Typed ActiveRecord find helpers | `Todo.find(1)`, `Todo.findBy({externalId: "x"})`, `relation.findBy({...})` | Initial query slice |
| Model associations/validations/enums/callbacks metadata | `@:belongsTo`, `@:hasMany`, `@:hasOne`, `@:validates`, `@:railsEnum`, `@:beforeValidation`, `@:railsCallback("after_commit")` | Implemented initial typed metadata validation |
| ActionController surface | `rails.action_controller.Base` | Implemented |
| Strong params macro | `ParamsMacro.requirePermit(this.params(), Todo.railsParamKey, [Todo.f.title])` | Typed field-ref validation implemented |
| Typed ActionView render locals | `ViewMacro.renderTemplate(...)` + `Template<TLocals>` | Implemented |
| RailsHx-owned template refs | `Template.of(ViewClass) : Template<TLocals>`, `Template.layout(LayoutViewClass)` | Initial checked-template slice |
| External Rails template locals | `Template.existing("path") : Template<TLocals>`; `Template.external("path")` as lower-level escape | Initial interop slice |
| Rails template artifact generation | `@:railsTemplate(...)` | Implemented |
| Rails HHX inline templates | `@:railsTemplateAst(...)` + `return <div>...</div>` | Initial page/partial helper slice |
| Typed Rails partial locals object | `render(locals:TLocals)` + `locals.foo` projection | Initial locals slice |
| Typed ActionView template AST | `@:railsTemplateAst(...)` + `H`/`HtmlNode`/`HtmlAttr` | Initial lower-level AST slice |
| Typed ActionView partial composition | `H.partial(...)` + `Template<TLocals>` | Initial partial/component slice |
| Typed ActionView route/helper calls | `H.linkTo(...)` + route externs | Initial helper slice |
| Typed ActionView form helpers | `<form_with scope=${Todo.railsParamKey}>`, `<text_field name=${Todo.f.title}>`, `<text_area>`, `<check_box>`, `<submit>` | Initial typed field-ref form slice |
| Typed HHX control/helper tags | `<if>`, `<for>`, `<link_to>`, `<partial>` | Initial template/helper slice |
| Typed HHX helper label children | static text or `${...}` expression children | Initial helper slice |
| Typed HHX nested helper slots | `<link_to>...</link_to>` block-form content | Initial slot slice |
| Raw ERB template escape hatch | `@:railsAllowRawErb` | Implemented for migration/interop only |
| Mixed Rails/RailsHx adoption sample | `examples/rails_interop_app` + `npm run test:rails-interop` | Initial compile/static smoke |
| Existing Rails boundary adoption generator | `bin/rails generate hxruby:adopt` / `rake hxruby:gen:adopt` | Initial explicit wrapper scaffold plus suggest-only discovery |
| Rails app install generator | `bin/rails generate hxruby:install` / `rake hxruby:gen:app` | Implemented |
| Route helper generator | `bin/rails generate hxruby:routes` / `npm run rails:generate-routes` | Hardened for named Rails routes, nested/resource params, namespaces, member/collection routes, optional segments, globs, and mount-like rows |
| Scaffold generator | `bin/rails generate hxruby:scaffold` / `npm run rails:scaffold` | Implemented |

The rows above describe the current Rails MVP. The deeper typed Rails compiler layer is tracked as RailsHx; see `docs/railshx-roadmap.md` and the `haxe.ruby-wpi` bead epic.

## Strict Boundary Policy

| Define | Status | Behavior |
| --- | --- | --- |
| `reflaxe_ruby_strict_examples` | Implemented | Rejects raw `__ruby__` injection in examples and tests/snapshots. |
| `reflaxe_ruby_strict` | Implemented | Rejects raw `__ruby__` injection in project sources. |
| `@:rubyAllowRaw` | Implemented | Narrow module/type escape hatch for policy-specific tests or framework-owned islands. |
