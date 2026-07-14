# RubyHx And RailsHx Production Readiness

RubyHx and RailsHx are intended for real Ruby and Rails applications, not only
compiler demonstrations. The production-readiness gate for the documented
`0.x` beta contract is satisfied when the checks and ownership rules in this
document stay green. This is still a beta contract: supported surfaces are
production ready, but new Rails/Ruby surfaces must be added through explicit
beads, tests, and compatibility notes before users should rely on them.

The contract covers two distinct starting points. Ruby-first teams can add
typed Haxe components to an existing system. Haxe-first teams can keep nearly
all owned library or application source in Haxe/HHX and use Ruby primarily as
the generated runtime target. Evidence for one path does not automatically
prove the other.

A stable `1.0` claim is a separate, stronger project-wide commitment. RailsHx
cannot be stable if the RubyHx compiler, runtime, interop, packaging, debugging,
or upgrade story underneath it is not stable. Conversely, compiler correctness
alone cannot establish that RailsHx is ready for production teams. The stable
gate therefore evaluates the whole authoring-to-deployment system across the
dimensions below.

Tracking epic: `haxe.ruby-bjv` RailsHx production readiness.

## Current Status

RailsHx now proves the main production shape:

- Framework-independent RubyHx examples prove Haxe-first compilation, readable
  generated Ruby, native Ruby callable boundaries, and runtime behavior.
- Haxe-authored Rails models, relations, controllers, params, migrations, routes,
  HHX templates, generators, and Rails interop can emit Rails-native artifacts.
- The canonical todo app and mixed adoption fixtures cover compile-time output,
  Ruby syntax, browser smoke, mandatory Rails runtime lanes, production asset
  checks, and release artifact shape.
- Strict examples reject raw `__ruby__`; raw ERB and external templates are
  explicit migration/interop paths rather than the default authoring style.

The production-readiness gate is closed for the documented beta surface:
mandatory runtime coverage, deploy evidence, API completeness audits, safe
escape-hatch policy, and Rails-native app/generator workflows are tracked and
covered. Future breadth remains normal beta evolution, not an implicit blocker
for the closed readiness gate.

Stable `1.0` has **not** been declared. It requires an independent evidence
review, closure of every resulting stable-release blocker, a public API and
compatibility commitment, and explicit release-policy approval. The review
packet is [RubyHx/RailsHx GPT 5.6 Pro 1.0 Review](rubyhx-railshx-gpt56-1.0-review.md).
The current best-effort single-maintainer ownership, intake channels, cadence,
and core/companion routing are published in
[Support And Maintenance](../SUPPORT.md).

## Supported Baseline And Adoption Guidance

RailsHx should be described as production-ready for the documented beta
contract, not as a stable `1.x` API. Teams should pin compiler/runtime versions,
keep generated artifacts in CI, run the gates below, and expect unsupported API
gaps to become explicit beads before broad rollout.

The current supported toolchain baseline is documented in
[Compatibility Matrix](compatibility-matrix.md): Haxe `4.3.7`, Node `22.14.0`
through the current tested `22.23.1` patch, and MRI Ruby `3.3`, `3.4`, and
`4.0` in CI. Ruby `3.3` is transitional. Generated Rails fixtures accept
`>= 7.0` and `< 8.0`, but that range is not a tested-minor support matrix.
The current Rails runtime evidence is the locked Rails `7.2.3.1` lane. Rails
8.1 support is planned under `haxe_ruby-nho0`, but it is unverified and not
currently supported. A combined stable `1.0` requires that runtime lane to pass;
otherwise RailsHx remains beta.

Support expectation for production-beta use:

- No silent production blockers: file or link a bead under `haxe.ruby-bjv`.
- No untracked unsafe shortcuts: raw Ruby/ERB/SQL/Dynamic paths must be explicit
  and documented.
- No unsupported-version promises: users should stay on the documented matrix.
- No stable `1.x` compatibility promise while public versioning remains `0.x`.

Haxe-first users should treat Haxe/HHX as the source of truth, generated Ruby as
a checked build artifact, and Ruby-level integration, operations, and debugging
as part of using the target ecosystem. Ruby-first adopters should keep ownership
boundaries explicit so generated workflows never overwrite Rails-owned source.

## Production-Ready Beta Definition

RailsHx can be called production-ready when all of these are true:

- `rake test`, `rake test:rails:runtime`, `rake todoapp:playwright`,
  packaging checks, release-contract checks, and snapshot checks are mandatory
  and green in CI for the supported toolchain matrix.
- A deployable RailsHx dogfood app proves compile, migrations, Rails tests,
  Zeitwerk, assets, and release artifact shape.
- Typed Rails APIs cover the common production path for models, migrations,
  controllers, params, routes, templates, jobs, mailers, storage, Turbo,
  ActionCable, instrumentation, and gradual adoption.
- Unsafe boundaries are explicit: raw Ruby, raw ERB, raw SQL/string clauses,
  unchecked file paths, `Dynamic`, and generated adoption contracts are either
  typed, fail-closed, or clearly opt-in with tests. SQL/string-bearing APIs
  follow [RailsHx SQL And String-Bearing API Policy](railshx-sql-string-policy.md).
- Rails-facing generators and dev/prod workflows feel Rails-native and better
  than hand-written boilerplate, with actionable diagnostics.
- Rails-owned runtime tasks stay Rails-owned: RailsHx compiles first, then
  `bin/rails db:migrate`, `bin/rails test`, `zeitwerk:check`, and
  `assets:precompile` consume the generated artifacts.
- Existing Ruby/ERB/Rails apps can adopt RailsHx incrementally without losing
  type safety at every boundary.
- Haxe-first users can author the documented framework-independent and Rails
  workflows without routinely editing generated Ruby or ERB.
- Docs tell users what is supported, what is still alpha, what commands prove
  readiness, and which versions are supported.

## Stable 1.0 Definition

Stable `1.0` means the documented supported scope is coherent, dependable, and
covered by an upgrade policy. It does not mean every Ruby gem, Haxe std module,
Rails API, database adapter, or deployment platform is implemented. Unsupported
surfaces may remain outside the contract when they are explicit, diagnostically
clear, and do not undermine a marketed core workflow.

The following dimensions form one release decision. Existing beta evidence is
an input, not automatic proof that a dimension is complete.

| Dimension | Stable `1.0` evidence required |
| --- | --- |
| Product scope and claims | RubyHx, RailsHx, `hxruby`, profiles, Haxe-first authoring, Ruby-first adoption, supported use cases, and non-goals are named consistently. Every material public claim has a repository proof or narrower wording. |
| Compiler and Haxe semantics | Supported typed expressions, control flow, classes, modules, functions, enums, exceptions, numeric/string/collection behavior, and both profile contracts are fail-closed and covered by snapshots plus runtime parity tests. Unsupported lowering never silently changes behavior. |
| Generated Ruby and runtime helpers | Output is deterministic, readable, syntax-valid, and Ruby-native where behavior permits. Every helper has documented ownership, compatibility, loading, versioning, and security policy; runtime-free claims are made only for fixtures that prove them. |
| Ruby stdlib and ecosystem interop | The supported std inventory is explicit. Blocks, keywords, rest/forwarding, constants, modules, mixins, monkey patches, gems, RBS, YARD, native extensions, and dynamic boundaries have typed contracts, diagnostics, examples, and honest unsupported cases. |
| Rails framework contract | The marketed Haxe-first and gradual-adoption paths across ActiveRecord, migrations, controllers, params, routing, ActionView/HHX, Hotwire, jobs, mailers, storage, tests, generators, and engines are Rails-native and tested. The TSX-like typed-view claim distinguishes compile-time guarantees from HTML/accessibility/browser behavior and proves normal ERB output without a client view runtime. Breadth gaps are classified as blocker, documented unsupported surface, or post-1.0 enhancement. |
| Authoring UX and API stability | Canonical Haxe APIs are typed, ergonomic, documented, discoverable in editors, and free of accidental compiler plumbing. A Haxe-first user can complete normal workflows without editing generated Ruby. Public packages, metadata, defines, generated manifests, diagnostics, and compatibility aliases have an inventory and deprecation policy. |
| Haxe-first authoring, gradual adoption, and ownership | Haxe-owned, Ruby-owned, and partial-ownership modes are each proven and fail closed on unsafe paths or unowned content. Existing Ruby can call generated code and typed Haxe can consume existing code without requiring a rewrite or leaking broad `Dynamic` contracts. Haxe-first evidence is not inferred from mixed-adoption evidence. |
| Full-stack Ruby/JavaScript sharing | At least one maintained reference flow proves selected shared types or behavior on both targets, with target-specific boundaries, serialization compatibility, client build integration, and two-target tests. The Genes custom-emitter, importmap rewrite, vendoring, stock-emitter alternative, and upgrade ownership are explicit. Docs do not imply that all application code should be isomorphic. |
| Tests and reference applications | Compiler snapshots, negative diagnostics, Ruby runtime parity, Rails matrix tests, Playwright, production builds, packaging checks, and executable examples cover each public workflow. Flake policy, failure triage, and generated-artifact determinism are documented. |
| Security and supply chain | Escape hatches, raw Ruby/ERB/SQL, paths, generated contracts, dependency/action pins, secrets, release permissions, artifact identity, and advisory boundaries have threat-oriented review and mandatory gates. No known critical/high issue remains open in the supported scope. |
| Performance and resource behavior | Representative compile time, generated-code runtime, startup, memory/allocation, artifact size, and Rails production behavior have measured baselines and regression policy. Claims are workload-scoped; unexplained material regressions block release. |
| Debugging and observability | Compile diagnostics, generated-source locations, Ruby stack traces, exception behavior, logs, instrumentation, source correlation, and production failure workflows are documented and exercised. Users can diagnose a generated application without treating compiler output as opaque. |
| Packaging, compatibility, and upgrades | Supported Haxe/Ruby/Rails/Node/platform versions are explicit and continuously tested. Reproducible packages, install/uninstall flows, SemVer boundaries, deprecation windows, migration guidance, generated-artifact upgrades, and rollback/recovery are proven. |
| Documentation and onboarding | A Ruby developer or Haxe-first adopter can evaluate, install, compile, run, test, debug, choose an ownership direction, deploy, and upgrade from maintained docs and executable examples. Generated projects inherit the operational and ownership guidance they need. |
| Maintenance and support | Release ownership, security reporting, compatibility decisions, issue triage, support expectations, dependency updates, and the distinction between core and companion packages are sustainable and publicly stated. A stable promise must have an owner, not only green code. |

### Stable 1.0 Exit Rules

The project may request `1.0.0` approval only when all of the following are
true:

- an evidence review covers every dimension above and records file, test,
  workflow, release, or runtime evidence rather than confidence alone;
- every P0 correctness, data-loss, security, or release-integrity finding is
  closed, and every P1 stable-release blocker is closed or removed from public
  scope with accurate diagnostics and docs;
- the supported API/metadata/define/generated-artifact inventory and SemVer
  boundary are reviewed, with deprecation and migration policy in place;
- the compatibility matrix and reference workflows pass on the exact release
  candidate, including Ruby compiler/runtime, Rails runtime, browser, production,
  and package-consumer lanes;
- performance, debugging/source-correlation, onboarding, upgrade, and support
  evidence exist; these dimensions cannot be waived merely because functional
  tests are green;
- the README and release notes use only claims supported by the final
  claim-evidence matrix;
- an independent reviewer challenges the result after blocker closure, and the
  stable-major policy approval explicitly records the decision.

The review should create or update beads for concrete gaps. “Needs more
confidence,” “support everything,” or “improve quality” are not actionable exit
criteria; each finding needs an owner, bounded outcome, evidence gate, and
severity tied to the documented supported scope.

## Tracked Work

The P0/P1 readiness gates below are closed. Non-blocking breadth and R&D should
be tracked as new follow-up beads without silently widening the production
contract.

| Bead | Gate | Required outcome |
| --- | --- | --- |
| `haxe.ruby-bjv.1` | Mandatory Rails runtime CI | `rake test:rails:runtime` is the local required gate for supported Ruby/Rails lanes, with clear failure staging. CI runs the underlying npm script directly. |
| `haxe.ruby-bjv.2` | Deployable dogfood app | A RailsHx app proves production compile, migrations, Rails tests, `zeitwerk:check`, `assets:precompile`, and release artifact shape. |
| `haxe.ruby-bjv.3` | Typed API completeness audit | Production Rails API blockers are inventoried in [RailsHx Typed API Production Gap Audit](railshx-typed-api-production-gap-audit.md) and converted into implementation beads. SQL/string-bearing APIs get a typed or explicit escape-hatch policy before implementation. |
| `haxe.ruby-bjv.4` | Escape-hatch/security audit | Raw Ruby, raw ERB, raw SQL, dynamic boundaries, file-backed macros, and generator inference are named in [RailsHx Escape Hatch And Security Audit](railshx-escape-hatch-security-audit.md) and are fail-closed or explicit opt-ins with tests. |
| `haxe.ruby-bjv.5` | Generator and workflow hardening | Install/scaffold/adopt/route generators, watch loops, client compilation, test flow, and production build flow are Rails-native and documented. |
| `haxe.ruby-bjv.6` | Gradual adoption hardening | Existing Ruby/ERB/Rails code can consume Haxe output and Haxe can consume existing app code through typed, checked contracts. |
| `haxe.ruby-bjv.7` | Public readiness checklist | User-facing docs state maturity, commands, versions, support expectations, known blockers, and release criteria. |
| `haxe.ruby-bjv.13` | Upstream Haxe std parity lane | Curated Haxe `unitstd` fixtures compile through the Ruby target and run on Ruby via `npm run test:unitstd-ruby`, giving RubyHx std/runtime parity evidence underneath RailsHx. |
| `haxe_ruby-hjm` | Typed Ruby core and stdlib catalog | A versioned inventory distinguishes core, stdlib, default gems, bundled gems, and platform-specific APIs; deterministic RBS-backed contracts grow precise `ruby.*` coverage without collapsing Ruby semantics into Haxe std. This is post-beta breadth unless a narrower marketed 1.0 workflow depends on a missing API. |

Generator/task ownership details are tracked in
[RailsHx Generators And Rails Tasks Design](railshx-generators-and-tasks-design.md).
Generated-file ownership details are tracked in
[RailsHx Generated Artifact Ownership](railshx-generated-artifact-ownership.md).
Historical follow-up beads under `haxe.ruby-bjv` covered manifest-backed
generated artifact ownership, production migration snapshots, namespaced Rails
generator hardening, schema adoption, migration-history collision checks, and
`hxruby:doctor` / `hxruby:check`.

## Graduation Gates

To maintain the production-ready beta contract, run and record:

```bash
npm test
npm run test:unitstd-ruby
rake test:rails:runtime
rake todoapp:playwright
rake todoapp:production
rake test:snapshots
rake test:strict_boundaries
rake test:sql_string_policy
rake package:haxelib:test
rake package:gem:test
rake ci:release_contracts
```

The dedicated CI Rails runtime job runs the underlying `npm run test:rails-runtime` across the
supported Ruby matrix (`3.3`, `3.4`, `4.0`). The local `npm test` path may skip
Rails runtime execution when generated-app bundles are absent, but the dedicated
runtime command and CI lane install those bundles and fail closed when Rails
cannot boot. Runtime smoke logs must identify the failing boundary with staged
labels such as `compiler`, `materialization`, `migration`, `request tests`, and
browser stages.

Snapshot tests are the primary RailsHx compiler-output contract. A production
surface should have committed snapshots for the generated Ruby/Rails artifacts
that define its public shape; smoke tests should only add targeted invariants,
negative compile failures, syntax checks, and thin Rails consumption seams that
snapshots cannot prove. Runtime Rails tests must stay focused on generated app
integration points such as autoloading, rendering, migrations, mail delivery,
storage services, ActionCable channels, assets, and production boot. Broad Rails
behavior belongs to Rails unless RailsHx introduces custom runtime logic.

The dedicated CI production dogfood job runs the underlying `npm run test:todoapp-production`
on the pinned Ruby lane. That command compiles server Haxe/HHX and Haxe-authored
client JS, materializes the Rails app, runs migrations/tests, runs
`zeitwerk:check`, precompiles production assets, creates
`examples/todoapp_rails/build/release/todoapp_rails_release.tgz`, and verifies the archive
contains generated RailsHx Ruby, ERB, JS, migrations, and initializer files.

For a generated or adopted Rails app, also run:

```bash
bundle exec rake hxruby:compile
bundle exec rake hxruby:compile:client
bundle exec rake hxruby:db:migrate
bundle exec rake hxruby:test
bundle exec rails zeitwerk:check
RAILS_ENV=production bundle exec rake hxruby:production
```

Generated apps expose the same production lane as `bin/railshx-prod`. The rake task is the CI/buildpack entrypoint; the bin script is the app-author convenience wrapper. Both must compile RailsHx server output and Haxe-authored client JS before Rails production checks run.

## Design Rules While Closing The Gap

- Prefer typed RailsHx APIs over raw strings or `Dynamic`.
- Generated Ruby should remain recognizable Rails code.
- Rails-owned code can stay Rails-owned; use typed externs, `Template.existing`,
  route sync, RBS/source-backed adoption, and explicit interop contracts.
- Haxe-owned Rails templates should default to HHX; raw ERB remains an explicit
  migration escape hatch only.
- Any filesystem-backed macro or generator must fail closed when referenced
  files/directories are missing.
- LLM assistance may propose adoption contracts, but generated code must still
  pass validation, Haxe compilation, Ruby syntax checks, and Rails runtime gates.
- Before adding a new unsafe RailsHx boundary, update
  [RailsHx Escape Hatch And Security Audit](railshx-escape-hatch-security-audit.md)
  and file or link the follow-up bead.
