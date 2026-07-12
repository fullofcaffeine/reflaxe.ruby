# haxe.ruby Docs

This repo has one compiler pipeline with multiple authoring layers:

- **RubyHx** covers pure Ruby output, Ruby std/runtime support, gem interop, Ruby extension APIs, and framework-independent Haxe-to-Ruby authoring.
- **RailsHx** is the Rails-first layer: typed ActiveRecord, ActionController, ActionView/HHX, generators, migrations, Turbo/importmap, tests, and Rails-native app workflows.

RailsHx is a first-class citizen, not a separate backend. Rails remains the runtime owner for `db:migrate`, `test`, Zeitwerk, assets, and app boot. RailsHx owns typed Haxe source, compile-time validation, generated Rails artifacts, and the developer UX around those artifacts.

Future Ruby framework layers should reuse the same split: add typed std/macros/generators for the framework, emit framework-native Ruby artifacts, and keep framework runtime tasks owned by the framework. Those layers can live here if they share compiler/runtime code tightly, or in separate repos that consume `reflaxe.ruby`/`hxruby`.

## Start Here

- [Compatibility Matrix](compatibility-matrix.md): supported Haxe, Node, and Ruby versions.
- [Ruby Callable And Method ABI](ruby-callable-abi.md): typed blocks, keyword/rest arguments, method values, forwarding, definitions, and diagnostics.
- [Ruby Compiler Correctness](compiler-correctness.md): exhaustive typed-expression ownership and fail-closed diagnostics.
- [Release Version Policy](release-version-policy.md): conventional major-zero releases, tag-derived lineage, and independent stable-major approvals.
- [Reproducible Release Artifacts](release-artifacts.md): tested-commit staging, canonical ZIP/gem bytes, full content manifests, SHA-256 sidecars, and consumer gates.
- [Tested-Commit Publication Workflow](release-publication-workflow.md): same-run release authorization, exact toolchain/action pins, minimal permissions, and trigger matrix.
- [Ruby Profiles](profiles.md): `ruby_first` vs `portable`.
- [Ruby Extension Interop](ruby-extension-interop.md): typed `include`, `extend`, monkey patches, externs, and metaprogramming-heavy library adoption.
- [Std Ownership](stdlib-ownership.md): how Ruby/Haxe std coverage is tracked.
- [Ruby Stdlib Parity Audit](ruby-stdlib-parity-audit.md): upstream Haxe std candidate accounting for Ruby.
- [Ruby Stdlib R&D Plan](ruby-stdlib-rd.md): staged typed stdlib coverage, runtime-helper policy, and follow-up beads.
- [Ruby Stdlib Facades](ruby-stdlib-facades.md): authoring typed `ruby.*` facades over Ruby stdlib APIs.
- [Gap Report Guidance](gap-report-guidance.md): updating std/runtime coverage inventory.

## RailsHx Guides

- [RailsHx Roadmap](railshx-roadmap.md): current Rails plan and sequencing.
- [Production Readiness](railshx-production-readiness.md): gap tracker for real Rails adoption.
- [Generator Workflows](railshx-generator-workflows.md): app-facing generator commands, generated artifacts, runtime handoff, diagnostics, and CI gates.
- [Generators And Tasks](railshx-generators-and-tasks-design.md): Rails-native generator/task ownership, generated starter skeleton, and `hxruby:start` workflows.
- [Generated Artifact Ownership](railshx-generated-artifact-ownership.md): manifest/header safety and overwrite policy.
- [Gradual Adoption](railshx-gradual-adoption.md): mixing existing Ruby/ERB with Haxe/HHX.
- [Gem Layers](railshx-gem-layers.md): wrapping installed Ruby gems through typed contracts and reusable companion packages such as future DeviseHx.
- [Gem-Layer Testing](railshx-gem-layer-testing.md): testing pyramid for reusable RailsHx companion packages over Ruby gems.
- [DeviseHx GPT 5.5 Pro Prompt](railshx-devisehx-gpt55-prompt.md): required pre-implementation design review packet for the reusable Devise companion layer.
- [DeviseHx Design](railshx-devisehx-design.md): folded GPT 5.5 Pro review, API shape, extraction strategy, escape hatches, tests, and rollout plan.
- [DeviseHx Release Lane](railshx-devisehx-release-lane.md): incubated package metadata, CI gates, security/release checklist, and standalone split criteria.
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
- [RailsHx Skeleton And Todoapp Tutorial](railshx-skeleton-and-todoapp-tutorial.md)
- [Haxe-Authored Testing Design](railshx-haxe-authored-testing-design.md)

## Examples

- `examples/hello_world`: smallest pure Ruby compile/run path.
- `examples/ruby_callable_abi`: canonical pure RubyHx callable ABI example,
  including a handwritten Ruby consumer and runtime-free generated calls.
- `examples/ruby_interop` and `examples/ruby_extensions`: consuming and authoring Ruby APIs from Haxe.
- `examples/active_support_facades`: typed facades over Ruby/Rails extension-style APIs.
- `examples/rails_routes_dsl`: focused Haxe-owned Rails route DSL fixture with
  committed `config/routes.rb` and route-manifest snapshots.
- `examples/rails_test_adapters`: focused Haxe-authored Rails test fixture for
  default Minitest and explicit RSpec adapter output.
- `examples/rails_interop_app`: gradual Rails adoption with existing Ruby/ERB seams.
- `examples/todoapp_rails`: canonical RailsHx dogfood app with HHX, ActiveRecord, migrations, DeviseHx, Haxe-authored JS, Rails tests, production smoke, and Playwright.

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
