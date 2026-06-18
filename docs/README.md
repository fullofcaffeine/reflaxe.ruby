# haxe.ruby Docs

This repo has one compiler pipeline with multiple authoring layers:

- **RubyHx** covers pure Ruby output, Ruby std/runtime support, gem interop, Ruby extension APIs, and framework-independent Haxe-to-Ruby authoring.
- **RailsHx** is the Rails-first layer: typed ActiveRecord, ActionController, ActionView/HHX, generators, migrations, Turbo/importmap, tests, and Rails-native app workflows.

RailsHx is a first-class citizen, not a separate backend. Rails remains the runtime owner for `db:migrate`, `test`, Zeitwerk, assets, and app boot. RailsHx owns typed Haxe source, compile-time validation, generated Rails artifacts, and the developer UX around those artifacts.

Future Ruby framework layers should reuse the same split: add typed std/macros/generators for the framework, emit framework-native Ruby artifacts, and keep framework runtime tasks owned by the framework. Those layers can live here if they share compiler/runtime code tightly, or in separate repos that consume `reflaxe.ruby`/`hxruby`.

## Start Here

- [Compatibility Matrix](compatibility-matrix.md): supported Haxe, Node, and Ruby versions.
- [Ruby Profiles](profiles.md): `ruby_first` vs `portable`.
- [Ruby Extension Interop](ruby-extension-interop.md): typed `include`, `extend`, monkey patches, externs, and metaprogramming-heavy library adoption.
- [Std Ownership](stdlib-ownership.md): how Ruby/Haxe std coverage is tracked.
- [Gap Report Guidance](gap-report-guidance.md): updating std/runtime coverage inventory.

## RailsHx Guides

- [RailsHx Roadmap](railshx-roadmap.md): current Rails plan and sequencing.
- [Production Readiness](railshx-production-readiness.md): gap tracker for real Rails adoption.
- [Generators And Tasks](railshx-generators-and-tasks-design.md): Rails-native generator/task ownership, generated starter skeleton, and `hxruby:start` workflows.
- [Generated Artifact Ownership](railshx-generated-artifact-ownership.md): manifest/header safety and overwrite policy.
- [Gradual Adoption](railshx-gradual-adoption.md): mixing existing Ruby/ERB with Haxe/HHX.
- [Gem Layers](railshx-gem-layers.md): wrapping installed Ruby gems through typed contracts and reusable companion packages such as future DeviseHx.
- [Testing Strategy](railshx-testing-strategy.md): snapshots, smoke tests, Rails runtime tests, and Playwright.
- [Typed API Production Gap Audit](railshx-typed-api-production-gap-audit.md): current typed API gaps.

## RailsHx API Areas

- [ActiveRecord Query Guide](railshx-query-guide.md)
- [Query Expression Design](railshx-query-expression-design.md)
- [Projection And Grouping Design](railshx-projections-grouping-design.md)
- [Controller Guide](railshx-controller-guide.md)
- [Routing Design](railshx-routing-design.md)
- [Components Guide](railshx-components-guide.md)
- [Turbo Guide](railshx-turbo-guide.md)
- [ActionCable Guide](railshx-action-cable-guide.md)
- [Full-Stack Hotwire Design](railshx-full-stack-hotwire-design.md)
- [ActionMailer Guide](railshx-action-mailer-guide.md)
- [ActiveJob Guide](railshx-active-job-guide.md)
- [ActiveStorage Guide](railshx-active-storage-guide.md)
- [Instrumentation Guide](railshx-instrumentation-guide.md)
- [Engines And Plugins Guide](railshx-engines-plugins-guide.md)
- [SQL String Policy](railshx-sql-string-policy.md)
- [Type Safety Review](railshx-type-safety-review.md)
- [Escape Hatch Security Audit](railshx-escape-hatch-security-audit.md)
- [Haxe-Authored Testing Design](railshx-haxe-authored-testing-design.md)

## Examples

- `examples/hello_world`: smallest pure Ruby compile/run path.
- `examples/ruby_interop` and `examples/ruby_extensions`: consuming and authoring Ruby APIs from Haxe.
- `examples/active_support_facades`: typed facades over Ruby/Rails extension-style APIs.
- `examples/rails_routes_dsl`: focused Haxe-owned Rails route DSL fixture with
  committed `config/routes.rb` and route-manifest snapshots.
- `examples/rails_interop_app`: gradual Rails adoption with existing Ruby/ERB seams.
- `examples/todoapp_rails`: canonical RailsHx dogfood app with HHX, ActiveRecord, migrations, Haxe-authored JS, Rails tests, production smoke, and Playwright.

## Local Public-Readiness Checks

```bash
haxelib install formatter
brew install gitleaks
rake hooks:install
rake format:haxe:check
rake security:gitleaks
npm test
```

The pre-commit hook formats staged `.hx` files with `haxe-formatter` and runs staged gitleaks. CI runs a full formatter check, the compiler/Rails matrix, release-contract checks, and secret scanning.
