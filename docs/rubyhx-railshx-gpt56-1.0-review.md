# RubyHx/RailsHx GPT 5.6 Pro 1.0 Review

Use this packet for an independent, repository-backed review before proposing a
stable `1.0.0` release. The review is intentionally broader than a feature-gap
brainstorm. It must test the product thesis, architecture, semantics, operating
model, compatibility promise, and market claims against evidence.

The reviewer should not implement fixes during the first pass. Its job is to
produce a falsifiable readiness report and bounded bead mutations. Run a second
independent pass after all stable-release blockers are closed.

## Prompt

You are the independent stable-release reviewer for `reflaxe.ruby`, also known
at the product layer as RubyHx, with RailsHx built on top of it. Perform a deep,
adversarial, evidence-based review of whether the project is ready to make a
stable `1.0` compatibility and production claim.

Do not answer from the README alone. Treat repository docs, closed beads, and
existing “production ready” language as claims to verify, not proof. Inspect
the implementation, generated snapshots, negative diagnostics, runtime tests,
examples, packages, release workflows, compatibility matrix, recent Git
history, and the latest relevant CI/release evidence. Clearly distinguish:

- evidence you inspected;
- commands you actually ran and their result;
- claims inferred from evidence;
- surfaces that remain untested or uncertain.

Do not equate feature count with stability. Stable `1.0` does not require every
Ruby gem, Rails API, Haxe std module, database, or hosting platform. It does
require a coherent supported scope, no known release-blocking gaps inside that
scope, stable public contracts, explicit unsupported boundaries, production
operability, and an upgrade/support commitment.

### Product Thesis To Test

The intended positioning is:

> RubyHx lets teams write typed Haxe and ship readable Ruby, adopting it one
> component or Rails feature at a time while keeping Ruby, Rails, Bundler, gems,
> and deployment workflows in charge at runtime.

RubyHx is meant to be a better authoring option for Ruby-bound code where static
guarantees, compile-time framework checks, generated references, or selected
Ruby/JavaScript implementation sharing justify a build step. It is not a claim
that Ruby is obsolete or that every Ruby file should be migrated.

RailsHx is the Rails-native layer on RubyHx, not a separate compiler or Rails
runtime. Haxe/HHX may own selected artifacts or a whole application; Rails must
still see and run ordinary Ruby, ERB, routes, migrations, jobs, tests, assets,
and framework behavior.

Generated output should be readable and Ruby-native where behavior permits.
“Ordinary Ruby” does not mean every program is helper-free: required `hxruby`
support must be explicit, versioned, packaged, tested, and documented.

Gradual adoption must work in both directions: existing Ruby should call
Haxe-owned output, and typed Haxe should consume existing Ruby/Rails/gems through
checked contracts. Shared full-stack code means selected suitable source can
compile to Ruby and JavaScript; it must not be marketed as proof that all code
should be isomorphic or that Ruby/JavaScript teams cannot already share schemas.

Test whether the repository actually supports this thesis and whether the
wording is credible to experienced Ruby and Rails developers.

### Local Context

Inspect these repositories when present:

- `/Users/fullofcaffeine/workspace/code/haxe.ruby`
- `/Users/fullofcaffeine/workspace/code/haxe.elixir.codex`
- `/Users/fullofcaffeine/workspace/code/haxe.compilerdev.reference`
- `/Users/fullofcaffeine/workspace/code/haxe.rust`

Use `haxe.elixir.codex` only as architectural inspiration for typed framework
authoring and native target output. Use `haxe.compilerdev.reference` for Haxe,
Ruby, and Rails source/reference material. Use `haxe.rust` only where its
release, compatibility, or compiler lessons are genuinely transferable; do not
copy target-specific performance/profile policy into Ruby.

Start with these `haxe.ruby` sources, then follow evidence into the code:

- `AGENTS.md`
- `README.md`
- `docs/README.md`
- `docs/why-rubyhx.md`
- `docs/railshx-production-readiness.md`
- `docs/compatibility-matrix.md`
- `docs/profiles.md`
- `docs/compiler-correctness.md`
- `docs/compiler-metadata.md`
- `docs/ruby-callable-abi.md`
- `docs/ruby-extension-interop.md`
- `docs/stdlib-ownership.md`
- `docs/ruby-stdlib-parity-audit.md`
- `docs/railshx-roadmap.md`
- `docs/railshx-testing-strategy.md`
- `docs/railshx-gradual-adoption.md`
- `docs/railshx-generated-artifact-ownership.md`
- `docs/railshx-type-safety-review.md`
- `docs/railshx-typed-api-production-gap-audit.md`
- `docs/railshx-escape-hatch-security-audit.md`
- `docs/railshx-sql-string-policy.md`
- `docs/release-version-policy.md`
- `docs/release-artifacts.md`
- `docs/release-publication-workflow.md`
- `docs/release-hosting-and-repair.md`
- `docs/release-live-evidence.md`
- `src/reflaxe/ruby/**`
- `std/ruby/**`
- `std/rails/**`
- `std/devisehx/**`
- `runtime/hxruby/**`
- `lib/hxruby/**`
- `scripts/ci/**`
- `scripts/release/**`
- `test/**`
- `examples/hello_world/**`
- `examples/ruby_callable_abi/**`
- `examples/ruby_interop/**`
- `examples/ruby_extensions/**`
- `examples/rails_interop_app/**`
- `examples/todoapp_rails/**`
- `.github/workflows/**`
- `package.json`, `Rakefile`, `haxelib.json`, and `hxruby.gemspec`

Use `bd prime`, `bd list`, `bd show`, `bd blocked`, and tracked
`.beads/issues.jsonl` history to understand open and closed work. Do not assume a
closed bead proves its acceptance criteria; locate the implementation and test.

When current external facts matter—supported Ruby/Rails/Haxe versions, security
advisories, package/release state, action versions, or upstream behavior—verify
them from primary sources and cite direct links. Do not browse merely to replace
local implementation evidence.

### Hard Architectural Constraints

Treat these as intentional product invariants unless the review finds they are
internally contradictory or harmful:

- `ruby_first` and `portable` are semantic profiles in one compiler pipeline;
  `idiomatic` is only a compatibility alias. Do not propose a public `metal`
  profile without a distinct measured Ruby contract.
- RubyHx remains a first-class pure Ruby target; RailsHx cannot become its only
  use case.
- Rails, Bundler, installed gems, and Ruby runtime behavior remain owned by the
  Ruby ecosystem. RailsHx supplies typed authoring, checked generation, and
  native artifacts.
- Haxe-facing APIs should exploit types, inference, macros, properties, enums,
  and generated refs where they improve UX. Exact Ruby-shaped facades remain
  available at intentional interop boundaries.
- Generated Ruby/Rails should look hand-written where behavior permits. Runtime
  helpers must be justified by Haxe semantics, not compiler convenience.
- New or changed application-facing code avoids `Dynamic`, `Any`, broad
  reflection, casts, raw Ruby, raw ERB, and raw SQL except at explicit,
  documented, audited boundaries.
- File-backed macros and generators fail closed. Generated-file ownership and
  source-of-truth direction are explicit.
- RubyHx/RailsHx core must not hard-code third-party gem/package names when a
  reusable generic contract belongs in core.
- Examples are executable QA contracts. The todo application is a reference
  production path, not sufficient evidence by itself.

### Review Method

1. Establish the exact reviewed commit, branch cleanliness, toolchain, open bead
   state, and latest canonical-main CI/release state.
2. Build a public-surface inventory: packages, metadata, defines, profiles,
   CLI/Rake/Rails commands, runtime helpers, generated artifact formats,
   ownership manifests, compatibility aliases, and companion-package boundaries.
3. Trace the canonical workflows end to end: minimal Ruby, Ruby callable
   interop, existing-Ruby adoption, greenfield Rails generation, Rails runtime,
   browser code, production build, package consumption, and upgrade/recovery.
4. For each advertised capability, identify compiler/snapshot evidence, a
   negative diagnostic when misuse is knowable, runtime evidence where target
   behavior matters, and user-facing documentation.
5. Search for contrary evidence: `Dynamic`, `Any`, `cast`, broad reflection,
   raw injection, TODO/FIXME markers, skipped tests, environment-dependent
   passes, untested helpers, package omissions, undocumented metadata, duplicate
   lowering, architecture leakage, stale examples, and claims broader than
   tests.
6. Run the most diagnostic focused gates first. Run the full documented
   graduation suite when the environment can support it. Record skipped or
   unavailable lanes as missing evidence, not green.
7. Compare the findings to the stable `1.0` dimensions and exit rules in
   `docs/railshx-production-readiness.md`.
8. Produce the report and bead plan before proposing implementation.

### Dimensions To Audit

For every dimension, assign `PROVEN`, `PARTIAL`, `MISSING`, or
`OUTSIDE DOCUMENTED SCOPE`, state confidence, and cite concrete evidence.

#### 1. Product goals and market credibility

- Are RubyHx, RailsHx, `reflaxe.ruby`, and `hxruby` understandable without
  insider context?
- Does the pitch explain why a Ruby developer should care before explaining the
  release machinery?
- Are “ordinary Ruby,” gradual adoption, better ergonomics, critical-component
  use, Rails integration, and shared server/browser code demonstrated rather
  than asserted?
- Which claims would an experienced Ruby developer reject as hype, imprecise,
  or dismissive of existing Ruby/JavaScript practices?
- Are costs and non-goals visible enough for an informed adoption decision?

#### 2. Architecture and ownership

- Is `RubyCompiler.hx` an orchestration entrypoint or still a convergence point
  for unrelated Rails/compiler concerns?
- Are compiler AST/lowering, Ruby std, runtime helpers, Rails modules,
  generators, client support, and companion layers separated by typed APIs?
- Is vendored Reflaxe usage, upstream patch provenance, and upgrade path clear?
- Are duplicate or transitional architectures creating inconsistent behavior?
- Can another Ruby framework layer reuse RubyHx without importing Rails policy?

#### 3. Compiler correctness and language semantics

- Does the supported Haxe expression/type/control-flow surface fail closed?
- Are Ruby/Haxe semantic differences deliberately assigned to `ruby_first` or
  `portable`, with parity tests for edge cases?
- Audit numbers, strings, equality, truthiness, nullability, arrays/maps,
  iteration, closures, recursion, returns, exceptions, enums/ADTs, inheritance,
  interfaces, properties, statics, initialization order, generics/erasure, and
  reflection boundaries.
- Are diagnostics source-positioned, actionable, stable enough to document, and
  negatively tested?

#### 4. Generated Ruby and runtime behavior

- Is output deterministic, readable, idiomatic, syntax-valid, and semantically
  direct where practical?
- Does generated naming avoid compiler artifacts leaking into normal code unless
  collision safety or Haxe semantics truly require them?
- Inventory every runtime helper and its loading/versioning/package contract.
- Can Ruby callers use generated constants, methods, modules, exceptions,
  blocks, keywords, and return values naturally?
- Do stack traces and exceptions remain diagnosable through generated output?

#### 5. Ruby stdlib, gems, and native interop

- Is std ownership explicit and is upstream `unitstd` coverage representative?
- Do blocks, proc/lambda strictness, `yield`/captured blocks, keywords, optional
  omission, rest/splat, method values, forwarding, requires, modules, concerns,
  mixins, monkey patches, symbols, IO/filesystem, JSON, binary data, time,
  process behavior, and native extensions have coherent contracts?
- Are extern, RBS, YARD, source inference, and gem adoption precise-or-omitted
  where appropriate, secure, and usable on metaprogramming-heavy libraries?
- Are unsupported or dynamic seams explicit and locally contained?

#### 6. Rails framework depth and native semantics

- Audit the marketed common path across ActiveRecord models/relations/queries,
  validations/associations/callbacks, migrations, controllers/params/lifecycle,
  routes/helpers, ActionView/HHX/components/layouts, Turbo, ActionCable, jobs,
  mailers, storage, instrumentation, tests, engines/plugins, generators, schema
  adoption, DeviseHx, assets/importmap, Zeitwerk, and production boot.
- Does authoring remain valid Haxe and generated output remain ordinary Rails?
- Are compile-time checks genuinely stronger and more ergonomic than stringly
  Ruby without adding excessive ceremony?
- Classify each breadth gap as a 1.0 blocker, explicit unsupported surface, or
  post-1.0 enhancement. Do not turn “all of Rails” into an unbounded gate.

#### 7. Public API and developer experience

- Inventory every public package, metadata marker, define, CLI/task, generator
  option, manifest, and output convention that SemVer may need to protect.
- Are canonical APIs intent-first and Haxe-idiomatic while target-shaped facades
  remain available where valuable?
- Do completion, type errors, macro diagnostics, watch loops, doctor/check tasks,
  generated project guidance, and common edit/test/debug cycles feel coherent?
- Identify aliases or experimental APIs that need removal, stabilization,
  deprecation, or explicit exclusion before `1.0`.

#### 8. Gradual adoption and ecosystem integration

- Prove Ruby-owned, Haxe-owned, and mixed ownership in real files and runtime
  calls, not only compile fixtures.
- Are generated manifests, marker blocks, conflict detection, path validation,
  route/schema/template discovery, and cleanup safe and reversible?
- Can a team start with one critical component and expand without forking its
  Rails workflow or converting unrelated code?
- Can existing gems and Ruby metaprogramming remain runtime-authoritative without
  poisoning app-facing APIs with `Dynamic`?

#### 9. Ruby/JavaScript full-stack sharing

- Identify what the reference app actually shares versus merely authors in the
  same language.
- Verify serialization, nullability, enum/value semantics, validation parity,
  route/DOM hooks, target guards, client packaging, asset integration, and tests
  on both outputs.
- Find a concrete maintained shared-code example or classify its absence
  honestly. Do not market same-language source sharing beyond the proof.

#### 10. Testing and release evidence

- Map each public claim to snapshots, negative compile checks, Ruby runtime,
  Rails matrix, browser, production, package-consumer, security, or release
  evidence.
- Audit whether smoke tests assert the right seam and snapshots own generated
  shape; find duplicated, brittle, skipped, or environment-softened gates.
- Verify every example is indexed by the example gate and has an output/runtime
  contract.
- Review flake handling, deterministic rebuilds, failure diagnostics, test
  duration, and whether CI actually runs all mandatory lanes on supported
  versions.

#### 11. Security and supply chain

- Threat-model raw Ruby, ERB, SQL, paths/symlinks, generated contracts, LLM
  suggestions, YAML/JSON/manifests, command invocation, generated files,
  dependencies, actions, secrets, package provenance, and release repair.
- Check whether every unsafe escape is named, documented, tested, and absent
  from canonical paths unless justified.
- Verify advisories and dependency state from current primary sources.

#### 12. Performance and resource behavior

- Measure representative compile time, incremental/watch latency, output size,
  Ruby startup, runtime throughput where RubyHx adds code, allocations/memory,
  Rails boot/request behavior, and client bundle impact.
- Compare generated/direct Ruby only on documented representative workloads;
  avoid universal “faster” or “zero-cost” claims.
- Define repeatable baselines and regression thresholds suitable for stable
  maintenance.

#### 13. Debugging and observability

- Follow compile errors, generated Ruby syntax errors, Ruby exceptions, Rails
  request/job errors, browser failures, and production-build failures from
  symptom to source.
- Review source locations/maps, generated-file readability, stack traces,
  exception wrapping, logs, instrumentation, and `hxruby:doctor`/`check` output.
- Determine whether a Ruby team can operate the system without compiler authors
  manually interpreting failures.

#### 14. Compatibility, packaging, and upgrades

- Validate the Haxe/Ruby/Rails/Node/platform matrix and clarify untested
  combinations.
- Audit Haxelib-compatible ZIP and gem contents, runtime/helper identity,
  install paths, generated apps, dependency ownership, reproducibility,
  immutability, release authorization, repair, and consumer verification.
- Define the `1.x` SemVer boundary for compiler behavior, profiles, APIs,
  diagnostics where documented, generator output, manifests, runtime ABI, and
  package layout.
- Prove an upgrade and rollback path across at least representative major-zero
  state into the release candidate; identify migration tooling/docs needed.

#### 15. Documentation, onboarding, and maintenance

- Attempt the README/quick-start, pure Ruby path, mixed adoption path, Rails app
  path, test/debug loop, production build, and package consumption as a new user.
- Check docs for stale names, insider assumptions, contradictory ownership,
  unsupported claims, missing examples, and generated-app guidance drift.
- Identify the human ownership model for releases, security reports,
  compatibility decisions, issue triage, dependency updates, companion
  packages, and long-term support expectations.

### Required Commands And Evidence

Use the repository’s documented prerequisites. At minimum, inspect or run the
following when the environment supports them, plus narrower diagnostics found
during the audit:

```bash
bd prime
bd ready
bd blocked
git status --short --branch
git log --oneline --decorate -30
npm test
npm run test:examples-compile
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
rake security:gitleaks
```

Record exact commands, versions, exit status, and relevant workflow URLs. A test
that exists but was not run is coverage design, not current release evidence. A
local pass does not replace the required canonical-main GitHub Actions result.

### Severity And Decision Rules

- **P0 / stop-ship:** known correctness, data-loss, security, release-integrity,
  or silently wrong-code issue in the supported scope.
- **P1 / blocks stable 1.0:** material gap in a marketed workflow, public API/
  compatibility definition, production operation, upgrade path, or required
  evidence dimension.
- **P2 / important follow-up:** meaningful breadth, ergonomics, evidence, or
  maintainability work that can remain explicitly outside the initial stable
  scope without making its claims misleading.
- **P3 / polish or research:** bounded improvement with no material effect on
  the stable contract.

Do not lower severity because a fix is difficult. Do not raise severity merely
because an API could be broader. Tie severity to user impact and the declared
supported scope. If narrowing a claim or scope is a valid alternative to
implementation, state both options and their tradeoff.

Use one of these final verdicts:

- `NOT READY — P0 STOP-SHIP FINDINGS`
- `NOT READY — P1 STABLE-RELEASE BLOCKERS`
- `READY FOR 1.0 RELEASE-CANDIDATE HARDENING`
- `READY TO REQUEST STABLE-MAJOR APPROVAL`

Only the last verdict is compatible with requesting `1.0.0`, and it still does
not replace the repository’s explicit stable-major policy approval.

### Required Output

Produce one review document ready to commit as
`docs/reviews/rubyhx-railshx-1.0-readiness-review.md` with:

1. Reviewed commit, date, environment, reviewer/model, scope, and evidence
   limitations.
2. Executive verdict and the five most important reasons.
3. Product thesis assessment, including a Ruby-developer credibility critique
   and recommended wording changes.
4. Architecture map and findings, especially compiler orchestration, Rails
   modularity, runtime/helper ownership, Reflaxe provenance, client boundary,
   generators, and companion packages.
5. Public surface and compatibility inventory.
6. A claim-evidence matrix with columns for public claim, exact proof, contrary
   evidence, confidence, allowed wording, and required follow-up.
7. A 15-dimension scorecard using `PROVEN`, `PARTIAL`, `MISSING`, or
   `OUTSIDE DOCUMENTED SCOPE`, with evidence and release consequence.
8. Findings ordered by severity. Every finding must include a stable ID, user
   impact, concrete repository evidence, why current tests/docs are insufficient,
   bounded required outcome, acceptance evidence, scope-narrowing alternative,
   and suggested bead title/type/priority/dependencies.
9. A test/evidence map that distinguishes existing coverage, tests actually run,
   current canonical-main CI, and missing proof.
10. A proposed initial stable support matrix and explicit exclusions.
11. A SemVer/API/deprecation/upgrade recommendation.
12. A prioritized path from current production-ready beta to release candidate,
    then to stable-major approval, with measurable exit criteria.
13. Open questions that truly require product-owner judgment. Do not use this
    section for questions the repository can answer.
14. Concrete `bd` mutations: update existing issues where ownership already
    exists; otherwise propose one bounded bead per actionable finding, with
    dependencies and links to the review IDs.

Also provide a short executive summary suitable for a project owner. Do not
implement the findings in this review pass, do not mark the existing beta gate
as failed merely because `1.0` has a stronger bar, and do not declare stable
readiness from self-authored documentation alone.

## After The Review

Fold accepted findings into the committed review and beads. Update the
production-readiness document whenever a finding changes the stable scope or
exit rules. Close blockers only with the acceptance evidence named by the
review. When all P0/P1 findings are closed, run this packet again in a fresh
independent context against the exact release candidate before requesting the
stable-major approval required by the release policy.
