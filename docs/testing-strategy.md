# RubyHx Testing Strategy And Agent Feedback Loops

This is the repository-wide testing contract. It explains how contributors and
automated coding agents should get fast feedback without confusing a small
local check with release-grade evidence. Rails-specific test-layer choices
remain in [RailsHx Testing Strategy](railshx-testing-strategy.md).

The five claim-bearing surfaces and their independent status, owners,
commands, examples, and residual risks live in
[RubyHx testing scorecards](testing-scorecards.md). The
[2026-08-01 convergence review](testing-strategy-review-2026-08-01.md) records
the incremental audit, red-state proof, oracle, tracer bullet, timings, and
deferred Beads. Do not replace those scorecards with one aggregate pass rate.

## Practical Model

One test command cannot serve every timescale well:

```text
edit
  -> changed semantic-owner test
  -> fast repository canary
  -> affected high-fidelity evidence
  -> full clean matrix
  -> exact-commit release proof
```

A **semantic owner** is the smallest test that directly owns the behavior being
changed. For example, `test:turbo-streams` owns typed Turbo stream lowering and
its Rails consumption seam; `test:ruby-ast` owns generic Ruby AST child and
printer invariants. Agents should run that focused owner during implementation,
then widen evidence as the change stabilizes.

The fast canary answers “did this checkout break across several central
boundaries?” It does not answer “is this change complete?” or “is every public
compatibility claim proven?”

## Independent Evidence Axes

Keep these results separate. A pass on one axis cannot substitute for another.

| Axis | Positive contract | Representative current evidence |
| --- | --- | --- |
| Portable Haxe | Haxe behavior preserved by the `portable` profile executes as Ruby. | Upstream `unitstd`, JSON issue parity, filesystem parity, core/runtime smokes. |
| Ruby compiler/native | Ruby-shaped calls, blocks, keywords, modules, facades, AST structure, and `ruby_first` behavior remain correct and idiomatic. | Compiler/AST tests, focused generated-shape and runtime smokes, snapshots, Ruby facade gates. |
| RailsHx | Rails consumes generated models, controllers, templates, jobs, mail, storage, Turbo, ActionCable, routes, and generators normally. | Focused compile/smoke tests plus mandatory Rails runtime lanes. |
| Browser/production | The canonical app works through a browser and deployable production build. | Playwright sentinel and production dogfood. |
| Distribution/release | Consumers receive reproducible, complete artifacts built from the exact tested commit. | Haxelib/gem package checks, security gates, release contracts, immutable hosted-release verification. |

The current upstream Haxe lane is meaningful partial evidence, not complete
official Haxe 4.3.7 qualification. It runs 43 active official-derived `unitstd`
fixtures, plus adjacent JSON issue and filesystem cases. Shared top-level
`unit.TestMain` classes and the general issue corpus remain staged work. One
public-install tracer now exercises representatives from both families and the
active unitstd lane, but it is deliberately not a full baseline.

The active inventory is pinned to official Haxe 4.3.7 commit
`e0b355c6be312c1b17382603f018cf52522ec651`. Of 67 official `unitstd` files, 43
are active in this bounded lane and 24 are explicitly inactive. One active
fixture is byte-identical, 36 are formatter-only adaptations, and six are
Ruby-lane adaptations with reasons, owners, and reviewable patches. Exact
upstream/local/diff hashes and 2,248 post-macro active assertion identities are
checked by `npm run test:unitstd-provenance`. Inactive, adapted, and
repository-authored cases never inflate the unmodified-official count.

## Feedback Rings

Budgets below are initial targets. Promote them to p50/p95 service objectives
only after enough comparable local and hosted samples exist.

| Ring | Use | Current command or owner | Evidence and limitation |
| --- | --- | --- | --- |
| R0 focused/editor | Every meaningful edit | `npm run test:<semantic-owner>`; advisory `npm run test:change-impact-explain -- --path <path>`; `hxruby:dev` for generated app rebuilding | Fastest localization. Explain mode recommends evidence but neither executes nor suppresses tests; the app watcher rebuilds affected HXML targets. |
| R1 local canary | After a coherent edit burst and before widening | `npm run test:agent-smoke` | Fixed checkout canary with per-stage timings and real Ruby execution. Warm state is allowed; not public-package or full qualification evidence. |
| R2 required PR | Clean primary merge evidence | Currently the complete `npm test` matrix plus independent jobs | Sound but not optimized: the same long aggregate runs on all three Ruby branches. No blocking affected-test selector exists yet. |
| R3 affected extended | Framework, browser, production, package, capability, or secondary-profile risk | Focused Rails runtime, Playwright, production, package, security, and release-contract commands | Run when the changed contract needs them; canonical CI currently runs the major product lanes broadly. |
| R4 main full | Full current repository backstop and future selector audit | Canonical main workflow | All 14 jobs and supported Ruby branches; 19 recent successful main samples have p50 40.2 minutes and p95 50.0 minutes. |
| R5 release | Published compatibility and artifact proof | Gated final release job after every required dependency | Exact tested SHA, cold rebuild, reproducible artifacts, security, immutable hosted release; never derived from R1/R2 selection alone. |

The cooperative `npm run test:queued` lease only prevents simultaneous local
Haxe-family full suites from competing for CPU, memory, and disk. It does not
change selection, cache results, or contribute additional correctness evidence.

## Agent Loop

### Behavior-first change contract

For every meaningful bug fix or behavior change, record the following before
broad automation: preconditions/input, compilation or action path, observable
result, error/edge behavior, owning product surface, and protected claim. Bead
acceptance criteria, a compact scenario table, or fixture metadata is enough;
Gherkin is not required.

Use the smallest faithful owner as the inner TDD loop: show it red for the
intended reason, implement the change, make it green, refactor, then run the
next real boundary. Record the failing command and concise failure in the Bead,
PR, or durable implementation note. A separate red commit is optional. When a
high-level Rails/browser/consumer test reveals a stable compiler or generator
defect, retain the representative real-boundary proof and add a focused
deterministic regression at the semantic owner.

Every new or materially changed expected result must identify an independent
oracle: a specification, manually reviewed minimal expectation, pinned
reference implementation, invariant/property, provenance-backed golden, or
real consumer behavior. The implementation under test must not generate its
own expectation. Snapshot changes require semantic review plus target
syntax/runtime evidence when those are part of the claim.

For a new capability, prove one narrow real tracer bullet before multiplying
fixtures. The usual compiler path is authored Haxe -> custom backend -> Ruby
syntax/build check -> real MRI observation; add package, Rails, or browser
boundaries only when the capability claims them. Assign every assertion to the
lowest layer that can still observe its defect class.

Use this sequence for implementation work:

1. Classify the change by semantic owner and evidence axes before editing.
2. Add or tighten the focused regression first. For a runtime claim, execute
   generated Ruby or Rails; source compilation and snapshots alone are not a
   runtime pass.
3. Run the focused owner after each coherent edit. Do not run `npm test` after
   every keystroke.
4. Run `npm run test:agent-smoke` after the focused test is green. Read
   `test/.generated/test-loop/agent-smoke.json` when timing, toolchain identity,
   or the first failing stage matters.
5. Run affected snapshots, negative diagnostics, Rails, browser, production,
   package, security, or release-contract tests according to the changed
   boundary.
6. Before claiming a compiler/framework slice complete, run the unchanged full
   local contract with `npm run test:queued`, plus mandatory Rails runtime and
   any applicable browser/production lanes.
7. Treat canonical exact-SHA CI as the authoritative clean matrix. A local
   canary or warm watcher never authorizes a release.
8. For compiler representation, runtime, ABI, package publication, security,
   migration, or public-claim changes, perform a separate review pass after
   implementation. Challenge red sensitivity, oracle independence, negative
   cases, mocked boundaries, selector omissions, scorecard laundering, and
   overbroad wording; record findings and dispositions.

### Failure and stopping rules

- Stop feature expansion when any applicable required test is red. Fix it or
  record a real external blocker before starting another slice.
- A failed canary stage remains nonzero and stops later stages. There are no
  automatic retries that turn red into green.
- An unsupported capability, quarantine, harness adaptation, or unexecuted test
  is not a compatibility pass.
- Unknown ownership, compiler-wide lowering, runtime/helper, std override,
  profile, test-runner, manifest, toolchain, package, or release changes must
  expand to broader/full testing.
- Preserve generated failure artifacts and the first actionable diagnostic.
  Do not refresh snapshots or weaken upstream assertions merely to obtain green.
- Do not optimize toward assertion count or a geometric test ratio. Review
  stable behavior owners, unique failure yield, escaped defects, diagnosis
  time, claim coverage, provenance, and maintenance cost. Formatting, lint,
  schema/freshness, workflow-policy, security, and manifest checks are the
  static floor and stay outside behavior-layer ratios.

## R1 Agent Canary

`npm run test:agent-smoke` intentionally reuses existing tests in cheap-first
order:

1. profile resolution and conflict diagnostics;
2. Ruby AST printer/child/scope contracts;
3. minimal Haxe compile, Ruby syntax, and Ruby execution;
4. portable/native exception behavior;
5. broader upstream JSON cases including issue regressions;
6. filesystem and binary-I/O capability behavior;
7. all currently enabled/adapted upstream `unitstd` fixtures.

An initial warm local sample on 2026-07-30 measured the seven underlying stages
at approximately 22 seconds total: profile 1.3s, AST 0.3s, hello-world 2.7s,
exceptions 2.8s, JSON 2.8s, filesystem 2.9s, and unitstd 9.0s. This is one
machine sample, not a p50/p95 promise. The complete snapshot aggregate measured
178 seconds in the same session, so snapshots remain affected/full evidence
rather than an unconditional R1 stage.

Nineteen recent successful canonical-main workflows provide an initial hosted
baseline: p50 40.2 minutes and p95 50.0 minutes from workflow start to
completion. This workflow-level sample does not yet separate queue, setup,
time-to-first-actionable-failure, or per-stage critical-path contribution; the
ownership/selector instrumentation stage must add those measurements before CI
is reshaped.

The canary report records source SHA, dirty state, exact Node/npm/Haxe/Ruby
versions, stage durations, exit results, selected stages, and the important
omitted evidence. `npm run test:agent-smoke-contract` executes a synthetic
failure and proves the runner returns nonzero and does not execute later stages.

## Current-State Gap Matrix

Evidence labels mean: **Observed** was read or executed in this checkout;
**Inferred** follows from observed structure but was not directly executed;
**Unknown** is not currently established.

| Layer | Existing evidence | What it proves | Gap and next owning seam |
| --- | --- | --- | --- |
| Compiler internals | **Observed:** AST, naming, decomposition, structural-reference, loop, diagnostics, callable tests, and advisory ownership mapping | Focused compiler invariants and conservative reverse-dependency recommendations | Compiler-core changes deliberately select every backstop; finer ownership requires miss evidence before narrowing. |
| Positive/negative source | **Observed:** many focused smoke scripts and invalid fixtures | Typed success and fail-closed diagnostics for shipped slices | Stable test IDs and aggregate timing are inconsistent across scripts. |
| Generated shape | **Observed:** committed deterministic snapshots; 178s local sample | Reviewable exact output and repeat generation | Too slow for unconditional R1; affected selection is not yet automated. |
| Target build/runtime | **Observed:** Ruby syntax checks and execution in focused lanes plus one isolated public-install tracer | Generated Ruby is accepted and behaves correctly for those bounded slices | The public-install tracer is representative, not full qualification. |
| Official Haxe | **Observed:** 43 active official-derived unitstd fixtures with exact provenance and active identities, JSON/filesystem parity, and public-install representatives from shared top-level, unitstd, and general-issue families | Partial portable runtime evidence through checkout and installed-package paths | The remaining shared classes, general issue corpus, and 24 inactive official files remain incomplete. |
| Rails/framework | **Observed:** focused smokes, snapshots, three-version runtime matrix | Rails consumes supported generated seams | Separate axis is healthy; do not count it toward portable Haxe pass totals. |
| Browser/production | **Observed:** Playwright and production dogfood | User-visible and deployable app paths | Expensive by design; select locally by affected product boundary while retaining canonical backstop. |
| Package/install | **Observed:** Haxelib ZIP, gem, package consumers, public upgrade | Current artifact shape and selected consumer paths | R1 uses checkout paths and must not be described as package-install evidence. |
| CI/release | **Observed:** 14-job exact-SHA workflow and immutable releases | Clean supported matrix and publication policy | PR and main currently share the expensive full shape; optimize only after selection observation data. |
| Agent efficiency | **Observed:** app watcher, heavy-run lease, measured R1 canary, and explain-only change-impact reports | Faster app rebuilds, contention control, quick cross-boundary feedback, and reviewable selected/omitted reasons | Selection is not blocking; rolling p50/p95, automated cross-job miss history, and flake history remain future evidence. |

## Staged Consolidation

1. **Instrument and establish R1.** Keep `npm test` authoritative, add the
   measured canary/report and failure-propagation contract, and collect initial
   timings.
2. **Harden official-source provenance** (`haxe_ruby-xm15`). Completed by the
   exact baseline, upstream/local hashes, six adaptation patches, active
   assertion identities, fail-closed inventory, and review-only sync.
3. **Add the public-install representative smoke** (`haxe_ruby-8dfj`).
   Completed: one command now installs the release-shaped ZIP in an isolated
   Haxelib repository, compiles pinned shared-language, unitstd, and general
   issue representatives, syntax-checks every generated Ruby file, executes
   MRI, and proves assertion/runtime failures propagate nonzero.
4. **Create an ownership manifest** (`haxe_ruby-28fa`). Completed: stable
   shards now map source owners to local/remote commands, product surfaces,
   axes, profiles, timeouts, artifacts, and safe broad/full fallbacks.
5. **Observe impact selection.** Active in advisory mode: selected and omitted
   shards are emitted with reasons alongside the unchanged full gate. Unknown
   or cross-cutting changes select every backstop, and known omitted failures
   are recorded as selector misses.
6. **Reshape CI only from evidence.** Use timing and selector-miss history to
   introduce a clean primary R2 and affected R3 while retaining full
   main/nightly and release backstops.

Compatibility wording remains unchanged until the complete applicable official
baseline passes through the public install path.
