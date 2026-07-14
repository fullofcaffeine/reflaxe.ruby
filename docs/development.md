# Repository Development

This guide collects contributor and repository-maintenance details that do not
belong on the product README. Application authors should start with
[Getting Started](getting-started.md).

## Install And Check The Checkout

```bash
npm install
npm test
```

`npm test` covers compiler/runtime smokes, exhaustive example compilation,
negative diagnostics, deterministic snapshots, strict-boundary policies,
generator behavior, release contracts, and package consumers. Rails runtime,
browser, and production gates remain separate because they install/boot full
applications:

```bash
rake test:rails:runtime
rake todoapp:playwright
rake todoapp:production
```

The complete release-readiness command set lives in
[RubyHx And RailsHx Production Readiness](railshx-production-readiness.md).

## Examples Are QA Contracts

Every `examples/*/Main.hx` entrypoint must be registered in
`npm run test:examples-compile`. Each example also needs an explicit
snapshot/smoke/runtime/browser contract; compile-only coverage is acceptable
only when snapshots or diagnostics completely own the behavior.

The highest-value entrypoints are:

- `examples/hello_world`: minimal compile/run.
- `examples/ruby_callable_abi`: typed blocks, keywords, forwarding, and a
  handwritten Ruby consumer.
- `examples/rails_interop_app`: mixed Ruby/ERB and Haxe ownership.
- `examples/todoapp_rails`: canonical Rails runtime/browser/production app.

See [RailsHx Testing Strategy](railshx-testing-strategy.md) for the evidence
pyramid.

## Snapshots, Smokes, And Runtime Tests

Snapshots own exact generated Ruby/Rails/ERB/JS shape and compile each case
twice to detect nondeterminism. Smoke scripts add focused invariants, invalid
compile cases, syntax checks, generators/packages, and thin consumption seams.
Runtime tests prove behavior that output inspection cannot, such as Rails
autoloading, rendering, migrations, jobs, mail, storage, ActionCable, browser
flows, and production assets.

Do not broadly retest Ruby or Rails behavior unless RubyHx/RailsHx introduces a
custom semantic boundary.

## Local Hooks

Install formatter and secret-scanning prerequisites, then the shared project
hooks:

```bash
haxelib install formatter
brew install gitleaks # or use another supported installation method
rake hooks:install
```

The hook formats staged `.hx` files and scans staged content with Gitleaks. CI
runs the full formatter, locked-dependency, and full-history security gates.

## Std And Runtime Inventory

The generated gap report is owned by `docs/stdlib-inventory.json`:

```bash
npm run test:gap-report
UPDATE_GAP_REPORT=1 npm run test:gap-report
```

Upstream behavioral parity is tracked independently by
`test/upstream_unitstd/manifest.json` and `npm run test:unitstd-ruby`. See
[Gap Report Guidance](gap-report-guidance.md),
[Std Ownership](stdlib-ownership.md), and
[Ruby Stdlib Parity Audit](ruby-stdlib-parity-audit.md).

## Issue And Git Workflow

Public bug reports, compatibility questions, and feature proposals enter through
[GitHub Issues](https://github.com/fullofcaffeine/reflaxe.ruby/issues). See
[Support And Maintenance](../SUPPORT.md) for routing and response expectations.

This repository uses `bd` beads. Run `bd prime` for the current workflow and
project memories, then use `bd ready`, `bd show`, `bd update --claim`, and
`bd close` around a bounded slice. The tracked `.beads/issues.jsonl` export is
committed with the work it describes.

Install the shared bead-aware hooks once after cloning:

```bash
bd hooks install --shared
```

The repository-level [`AGENTS.md`](../AGENTS.md) is the authoritative design and
workflow policy for agent-assisted changes.

## Repository Map

- `src/reflaxe/ruby`: compiler orchestration, typed Ruby AST/lowering, naming,
  build context, and focused Ruby/Rails compiler modules.
- `std/ruby`: typed Ruby std/interop surfaces.
- `std/ruby/_std`: upstream Haxe std overrides in source-checkout layout.
- `std/rails`: typed Rails authoring APIs and compiler-erased markers.
- `runtime/hxruby`: shared Ruby semantic helpers copied into generated output.
- `lib/hxruby`: Ruby gem, Rails generators, and Rake workflows.
- `haxe_libraries`: installed package definitions for Ruby server and RailsHx
  browser builds.
- `examples`: executable product and compiler contracts.
- `scripts/ci`: snapshot, smoke, policy, generator, package, and release checks.
- `scripts/rails`: repository-facing Rails helpers and the todoapp lifecycle.
- `test/snapshots`: committed generated output contracts.
- `vendor/reflaxe`: the pinned compiler framework plus its patch ledger.

## Focused Documentation

- [Compiler Correctness](compiler-correctness.md)
- [Compiler Metadata](compiler-metadata.md)
- [Ruby Callable And Method ABI](ruby-callable-abi.md)
- [RailsHx Production Readiness](railshx-production-readiness.md)
- [Packages And Installation](packages-and-installation.md)
