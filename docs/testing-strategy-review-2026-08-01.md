# Testing-strategy convergence review - 2026-08-01

## Outcome

The 2026-07-30 feedback-loop refactor remains intact. This incremental review
adds evidence boundaries that were still implicit: five product-surface
scorecards, exact official-fixture provenance, executable example claim tiers,
and a durable behavior-first/TDD/oracle/tracer record. It does not shorten the
required PR gate, change CI selection, add retries, or broaden compatibility.

## New-conclusion audit

| Conclusion | Before this delta | Disposition |
| --- | --- | --- |
| Concrete behavior scenarios | Partial: Beads and focused fixtures often contained them, but the repository strategy did not require all scenario fields. | Implemented in the repository strategy; the provenance scenario below is the representative worked example. |
| Lowest-faithful-layer TDD with red evidence | Partial: focused owners existed; red-state recording was not a durable rule. | Implemented in guidance and Bead evidence. |
| Independent oracle/provenance | Partial: many manual expected outputs and upstream references existed; official fixture bytes were not pinned. | Implemented for active unitstd fixtures and required for materially changed expectations. |
| One tracer bullet first | Satisfied in infrastructure but implicit: hello world and unitstd already compiled Haxe through Ruby execution. | Made explicit and recorded below; no duplicate tracer harness added. |
| Lowest faithful layer and double lock | Partial: the Rails strategy separated snapshots/smokes/runtime/browser, but the cross-repository rule was implicit. | Implemented in the repository strategy and scorecards. |
| Portfolio review rather than quotas | Satisfied: the prior strategy already rejected test-count and CI-minute optimization. | Preserved; provenance and stable owners are the governing measures. |
| Executable example tiers and proof levels | Partial: all 32 examples compiled and had a hard-coded coverage contract, but tiers and exact claim levels were absent. | Implemented in `test/example-contracts.json` and enforced by the existing example gate. |
| Preserve R0-R5 and safe affected selection | Satisfied/partial: rings, sentinels, failure propagation, broad fallback, and backstop were documented; the ownership selector remains staged. | Preserved without topology change; `haxe_ruby-28fa` remains the selector owner. |
| Separate high-risk review | Absent as a durable testing-strategy artifact. | This document owns findings and dispositions; the final verification section is completed after implementation gates. |
| Five independent scorecards | Absent: the prior axis table was useful but broader and blended some requested surfaces. | Implemented in `docs/testing-scorecards.md`. |

## Measured baseline before topology changes

All local samples used the existing dependency/toolchain installation. “Cold”
below means generated test output was rebuilt from source; it is not a clean
`npm ci` or release machine. Both sampled commands already delete their own
generated output, so their second run is a process-warm comparison, not a cached
semantic pass.

| Ring/path | Cold sample | Warm sample | Evidence |
| --- | ---: | ---: | --- |
| R0 official-fixture owner, `test:unitstd-ruby` | 9.81 s | 9.49 s | Full custom compile and Ruby execution each time |
| R1 `test:agent-smoke` | 22.60 s | 22.11 s | Seven existing stages; all generated/runtime work reran |
| R2 current required PR/full Ruby lane | 38.6-41.1 min | Not cache-comparable | CI 30586074436, three clean MRI jobs; PR and main currently use the same full shape |
| R3 browser | 2.5 min | Not cache-comparable | CI 30586074436 |
| R3 Rails runtime | 9.7-12.2 min | Not cache-comparable | CI 30586074436, MRI 3.3/3.4/4.0 |
| R3 production | 2.2 min | Not cache-comparable | CI 30586074436 |
| R4 whole workflow | 42.1 min | Not cache-comparable | CI 30586074436 |
| R5 publication step | 0.5 min after all dependencies | Cold rebuild inside the job; no reusable evidence cache | v1.22.0 run 30576903887 |

The earlier 19-run sample remains p50 40.2 minutes and p95 50.0 minutes for
successful canonical-main workflows. No topology changed in this delta, so the
expected before/after latency is neutral apart from sub-second manifest/hash
validation. The completion run records actual post-change focused and full
timings.

### Post-change samples and completion evidence

| Ring/path | Cold sample | Warm sample | Result / interpretation |
| --- | ---: | ---: | --- |
| R0 official-fixture owner, `test:unitstd-ruby` | 10.04 s | 11.35 s | Green; no semantic cache is reused |
| R1 `test:agent-smoke` | 29.06 s | 30.80 s | Green; all seven stages reran |
| R2 full local contract, `test:queued` | Not separately timed | Not applicable | Green through snapshots and both package builds |
| R3 mandatory Rails runtime | 544.70 s | Not sampled | Green against real Rails 8.1.3.1 |
| R3 flagship Chromium | 53.33 s | Not sampled | 15/15 Playwright tests passed |
| R3 flagship production | 14.13 s | Not sampled | 26 runs, 231 assertions, eager load, and release archive passed |

The focused post-change samples ran while other Haxe-family compiler processes
were consuming the same machine. Their roughly 0.2-8.7 second increase over the
baseline is therefore recorded as noisy observation, not attributed to this
delta. The added normal-path work is deterministic local JSON/hash validation;
the explicit external-reference review remains outside ordinary test runs.

## Representative behavior-first workflow

| Scenario field | Concrete contract |
| --- | --- |
| Preconditions/input | Haxe 4.3.7 official `.unit.hx` source at commit `e0b355c6be312c1b17382603f018cf52522ec651`, a checked-in local fixture, and its explicit registration in `test/unitstd_ruby/src_haxe/Main.hx` |
| Action | Validate provenance, compile the fixture through the custom portable Ruby backend, emit Ruby, and run MRI |
| Observable result | Exact upstream/local/diff hashes match; an active assertion identity survives macro expansion/emission; Ruby exits zero and prints `unitstd-ruby ok` |
| Error/edge behavior | Missing baseline, changed bytes, stale/missing adaptation diff, new/missing upstream file, lost active identity, failed assertion, or Ruby failure remains nonzero |
| Product surfaces | Provenance scorecard owns source identity; compiler scorecard owns Haxe-to-Ruby behavior; runtime scorecard owns MRI execution. None borrows another's green result. |
| Protected claim | The bounded active official-derived subset is reproducible and executed. It remains partial and is not full official target qualification. |

### Red-state evidence

The focused contract was added before the manifest implementation. Running
`npm run test:unitstd-provenance` failed for the intended reason:

```text
Error: unitstd manifest must pin the exact upstream Haxe baseline commit
```

The command and failure are also recorded on `haxe_ruby-xm15`. A separate red
commit was unnecessary because the failure preceded the implementation in the
same reviewable work session.

### Independent oracle

The source oracle is the official Haxe 4.3.7 tag and commit, not RubyHx. The
checker independently hashes the pinned upstream file, local fixture, Haxe
license, and six stored adaptation patches. Expected runtime behavior remains
the upstream assertion expression or a separately authored local invariant; the
compiler under test does not generate its own expected values.

The active-assertion inventory is a freshness lock, not a semantic oracle. It
records which assertion messages survive registration and macro expansion.
Semantic correctness still requires the real Ruby run.

### Tracer bullet and double lock

The existing unitstd path is the narrow real tracer bullet:

```text
official Haxe source
  -> checked provenance and registration
  -> UpstreamUnitStdMacro
  -> custom portable Ruby backend
  -> generated Ruby
  -> MRI assertion/runtime observer
```

The static provenance check diagnoses source/registration drift cheaply. The
retained `test:unitstd-ruby` vertical run proves the cross-language boundary.
Repository-authored focused regressions remain separate from official counts.

## Evidence efficiency and maintenance

The delta adds no new behavior fixture merely for volume. Its unique evidence is:

- exact reproducibility for 44 active official-derived fixtures;
- explicit nonpassing status for 23 inactive official files;
- 2,264 post-macro active assertion identities;
- six reviewable Ruby-lane adaptation patches;
- one machine-readable contract for all 32 maintained examples;
- five claim-separated scorecards.

The ongoing cost is hash/schema validation plus review when the pinned Haxe
baseline or an example contract intentionally changes. Formatter-only changes
use exact upstream/local hashes and a named transformation; only the six
semantic/harness adaptations carry patch files.

## Selector, flake, retry, and quarantine state

No blocking affected selector exists, so no selector-miss rate can honestly be
reported yet. `haxe_ruby-28fa` owns explain mode, semantic-owner/surface
mapping, always-run sentinels, conservative full fallback, and observation
before promotion. The unchanged full main workflow remains the selector
backstop.

Deterministic compiler, manifest, assertion, syntax, and runtime failures are
not retried. CI matrices use `fail-fast: false` to collect independent version
results; that is not a retry. No applicable test is currently quarantined by
this strategy. A future quarantine must name an owner, Bead, evidence, reason,
expiry, and nonblocking execution, and cannot count as passing compatibility.

## Separate high-risk review

This section is intentionally distinct from implementation. Before closure,
review the finished diff against these questions and record disposition:

| Challenge | Finding / disposition |
| --- | --- |
| Was the contract genuinely red? | Confirmed first by the missing-baseline failure above, then by the public-install contract's missing-report failure. The first real tracer also failed on Haxe/Ruby negative-remainder drift before the focused fix. |
| Is the oracle independent? | Official Git bytes and official assertion values are independent of RubyHx; real MRI observes the target result. Active identities are correctly described only as freshness evidence. |
| Are negative cases missing? | Provenance self-tests mutate every owned identity. The public artifact is additionally invoked in intentional assertion- and runtime-failure modes, and both must exit nonzero with distinct markers. |
| Does a mock erase a claimed boundary? | No mocks are introduced. The tracer builds the release-shaped ZIP from Git, installs it in a fresh Haxelib repository outside the checkout, invokes Haxe, syntax-checks generated files, and runs MRI. |
| Can selection omit this change? | No selection change exists; the full gate now includes the artifact-reuse tracer after the canonical Haxelib package build. The future ownership manifest must keep provenance and package-install sentinels conservative. |
| Is evidence laundered across scorecards? | Scorecards explicitly separate provenance, compiler, runtime, package/interop, and examples. |
| Are claims overbroad? | Compatibility remains partial; inactive/adapted cases cannot be counted as unmodified passes, and the three representative families are not described as a full official baseline. |

The review also found and corrected a hermeticity risk: an ordinary test must
not change behavior because a developer has an unrelated neighboring Haxe
checkout on another commit. Normal checks now use only committed provenance;
the external checkout is read solely by explicit review/update commands.

Final verification also passed `format:haxe:check`, `git diff --check`, the
release prose contract, and the repository-history gitleaks scan. No retries or
quarantines were used. Canonical exact-SHA CI remains required after push; its
result is recorded in the owning Beads and repository history rather than
predicted from local success.

## Public-install convergence addendum

`haxe_ruby-8dfj` implemented the deferred representative tracer without
broadening official qualification. The pre-implementation report contract was
red because no machine report existed. Its first real package/runtime execution
then found a genuine portable-operator defect: official `TestOps.hx` requires
`-101.5 % 100 == -1.5`, while Ruby floor-modulo returned `98.5`. The focused
owner now verifies signed Int/Float remainder, Float zero-divisor `NaN`, and
expression-valued `%=` writeback; the installed-package tracer retains the
official expectation as the independent vertical oracle.

The cold release-shaped run took 5.803 seconds and the artifact-reuse run took
4.443 seconds on the recorded local toolchain. Both executed 65 top-level
official assertions, syntax-checked the complete generated Ruby inventory, and
observed exit code 1 from both intentional failure modes. Machine, human,
generated-output, and per-stage log evidence is written beneath
`test/.generated/public_install_official`.

## Deferred findings

- Complete shared top-level and issue corpus qualification remains later work;
  this delta does not create a false aggregate Bead or compatibility claim.

## Change-impact observation addendum

`haxe_ruby-28fa` added the deferred explain-only selector without changing test
topology. The machine ownership map separates the five product surfaces and
records local commands for every hosted test shard, while compiler, runtime,
stdlib, profile, runner, manifest, package, workflow, toolchain, security,
release, and unknown paths fail safely to every canonical backstop.

The pre-implementation inventory observed that no ownership manifest, explain
command, or report existed; this slice did not pretend that absence was an
executed red test. The earlier public-install tracer remains this audit's
recorded real red-to-green workflow. Focused selector verification now covers ordinary documentation,
Rails, browser, compiler, runtime, stdlib, package, workflow, selector-self,
and unknown changes. An injected omitted `rails-browser` failure produces one
selector miss; selecting the same browser owner produces none. This fixture is
a sensitivity check, not a fabricated claim that hosted CI encountered a real
miss.

Canonical CI prints the initial advisory report from the full-history security
job and retains the complete three-Ruby `npm test` matrix plus independent
Rails runtime, browser, production, format, compatibility, security, and
release-contract jobs. `haxe_ruby-4jsz` adds automatic per-run cross-job
correlation: a final read-only job records the recommendation together with
every unchanged hosted backstop conclusion and retains the JSON artifact for
30 days. Failures in omitted shards become misses; cancellation or skipping
remains incomplete evidence. Cross-run p50/p95 summaries, a selected-job
completion aggregator, and any blocking CI selection remain deferred until
enough representative observation evidence exists; a later topology change
must retain full main/nightly and release backstops.

### Separate selector-risk review

| Challenge | Finding / disposition |
| --- | --- |
| Test sensitivity | Representative focused, full-fallback, unavailable-diff, selector-self, and unknown paths are hard-coded independently of the JSON rules. Removing an owner, command, sentinel, backstop, surface, or timeout makes the contract fail. |
| Oracle independence | Expected product surfaces and hosted job owners come from the existing scorecards and canonical workflow, not from values generated by the selector. The injected omitted failure is explicitly a harness sensitivity proof. |
| Missing negative cases | Empty/unreadable diffs select full; stale npm script references, unknown shard references, unknown observed failures, and unowned paths fail closed. |
| Mocked boundaries | Explain mode does not claim runtime correctness. Existing real Haxe/Ruby/Rails/browser/package jobs remain the behavior observers and are unchanged. |
| Selector omissions | Bounded Rails/browser/example rules may still omit a reverse dependency; the report makes omissions visible, accepts backstop-observed failures as misses, and cannot authorize skipping CI. |
| Scorecard laundering | Rules and shards carry the five independent product-surface IDs. Documentation-only changes carry no behavior surface, and Rails evidence does not advance compiler qualification. |
| Overbroad claims | No miss rate, CI speedup, affected-only safety, or complete official compatibility is claimed. Per-run cross-job correlation is now automated; cross-run review and a selected-job completion aggregator remain prerequisites for later promotion. |

The `haxe_ruby-4jsz` implementation received a separate post-implementation
risk pass before broad verification:

| Challenge | Finding / disposition |
| --- | --- |
| Failure sensitivity | The contract injects a hosted browser failure against both an omitted documentation recommendation and a selected browser recommendation. Only the former is a miss. Removing any canonical backstop from the explicit job map fails its equality check against `fullBackstop`. |
| Scheduler ambiguity | Job conclusions cannot identify the failing command inside the three-Ruby aggregate. The report therefore claims scheduler-shard granularity only; it never attributes a more specific semantic owner from the aggregate result. |
| Cancellation and skipping | These states are incomplete observations, not behavior failures. They remain explicit in the artifact and the unchanged release gate still rejects them directly. Missing or unknown results fail report generation. |
| Artifact authority | The 30-day JSON artifact is advisory historical evidence. It cannot advance a scorecard, schedule a selected test, prove selected-job completion, or replace runtime output. Missing artifact bytes fail the observer job. |
| Publication bypass | Release still names and checks every original gate and now also requires a successful observer. Workflow-policy tests reject a missing observer, missing original gate, cancellation, skipping, failure, and unpinned upload action. |

Local incremental evidence for the observer passed the focused selector and
release-workflow contracts, the complete queued suite, mandatory Rails 8.1.3.1
runtime, Chromium 15/15, production 26 runs/231 assertions, all five viability
workloads, Haxe formatting, Node/Ruby advisories, and full-history secret
scanning. A local all-green eight-backstop observation completed in 1 ms with
zero failures, misses, or incomplete lanes. This is a functional timing sample,
not a hosted latency distribution; the existing pre-observer p50/p95 baseline
remains the comparison point until retained hosted artifacts accumulate.

Hosted implementation workflow
[`30726407037`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/30726407037)
passed all 15 jobs for
`1ac27da09cd890bcad68fa919f368bbe2625846a`. The observer job
[`91442052130`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/30726407037/job/91442052130)
started only after all 13 pre-existing test executions had succeeded. Its
downloaded 2,414-byte artifact
[`8826891680`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/30726407037/artifacts/8826891680)
bound the exact base/head pair and 12 changed paths to all eight successful
hosted backstop conclusions, with zero failures, misses, or incomplete lanes
and a 300 ms selector runtime. The workflow/policy change correctly selected
full fallback. The final analyzer reported `no release`.

That run exposed a non-failing hosted warning because upload-artifact v4 still
declared Node 20 and GitHub was forcing it onto Node 24. The follow-up pinned
the verified official v7.0.0 commit, whose action metadata natively declares
Node 24. Cleanup workflow
[`30727730366`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/30727730366)
then passed all 15 jobs for
`970266e5fd5f167597fbc956cd7283b61f45029b`. Observer job
[`91445575638`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/30727730366/job/91445575638)
uploaded the 2,037-byte artifact
[`8827303071`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/30727730366/artifacts/8827303071)
with archive SHA-256
`a64ed04522927dd58f8a46b6f64d823f4df627675733ad43fdfcd759ef3cb342`.
Independent download again found eight successful outcomes, zero failures,
misses, or incomplete lanes, and a 3 ms selector runtime; the Node 20 warning
was absent. The final analyzer again reported `no release`. These are the first
two retained observations, not a miss-rate or latency distribution.

### Local completion evidence

- `npm run test:change-impact-selector` passed its schema, semantic-owner,
  product-surface, local-command, focused-selection, full-fallback, explain,
  and injected-miss contracts. Local explain calls completed below the
  millisecond report resolution; this is not a hosted latency promise.
- `npm run test:agent-smoke` passed all seven stages in 30.648 seconds in the
  measured warm-allowed run. The unchanged `npm run test:queued` contract then
  passed all compiler, runtime, stdlib, example, snapshot, generator, package,
  and release-contract owners, including 32 examples, the 737-file Haxelib
  ZIP, public-install official tracer, and gem.
- The independent mandatory Rails 8.1.3.1 runtime lane passed; Chromium passed
  15/15 scenarios; production passed 26 runs and 231 assertions plus eager
  loading and release-archive creation. All five stable viability workloads
  remained within their broad runaway caps.
- Haxe formatting, `npm audit`, Ruby advisory checks, the vulnerable-fixture
  sentinel, full-history Gitleaks over 916 commits, workflow policy, and
  support-matrix checks passed. No retry or quarantine converted a failure.

The full local wall time was affected by unrelated simultaneous Haxe-family
compiler processes and is therefore retained as noisy observation rather than
before/after selector evidence. Required PR test commands are unchanged: every
pre-existing job and the three-Ruby full matrix still run. The workflow now
exposes 15 jobs because the observer is its own bounded, read-only job.

Canonical implementation workflow
[`30719877635`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/30719877635)
passed all 14 jobs for
`b6b0cab30ebf9ebe4c8aa1a370652c00be33bb08`. Hosted explain mode classified
all 10 changed paths in 4 milliseconds, selected both central sentinels and
every canonical backstop because the workflow, package manifest, selector, and
ownership manifest changed, and remained advisory while every full lane ran.
The final release analyzer correctly reported `no release` for the `test:`
commit.

### 2026-08-02 incremental compiler-conformance workflow

Bead `haxe_ruby-3ir9` promoted the pinned official
`EvaluationOrder.unit.hx` fixture after it exposed a real compiler defect. The
pre-activation contract was intentionally red:

```text
node manifest assertion -> RED (expected): EvaluationOrder official runtime proof is inactive, not active
```

The first faithful tracer run then compiled the formatter-normalized official
fixture through Reflaxe.Ruby and failed under MRI with `NoMethodError` because
`d.f1()` on a `Dynamic` anonymous object was emitted as direct Ruby method
dispatch. The independent oracle is the Haxe 4.3.7 fixture at commit
`e0b355c6be312c1b17382603f018cf52522ec651`: its manually reviewable side-effect
buffer expectations define call, argument, short-circuit, indexing, and object
construction order without reusing the Ruby compiler's algorithm.

`RubyReflectiveFieldSemantics` now owns the Dynamic-field classification, and
the compiler treats an immediately called reflective field as a field-value
lookup followed by the ordinary function-value call path. A focused generated-
shape assertion rejects direct `Hash#f1` dispatch, while the retained vertical
test executes all 16 upstream expectations with MRI. This advances only the
compiler-conformance and provenance scorecards; it does not claim a new Ruby
stdlib API.

The first broad run correctly stopped when `RubyCompiler.hx` exceeded its
14,485-line orchestration ceiling. Extracting the classification restored the
one-way service boundary at 14,484 lines and 779 functions. The next run
correctly stopped on the raw/print inventory freshness gate; the reviewed
refresh retained exactly 269 sites, and an independent comparison found every
non-line field unchanged. These were architecture-ledger findings, not behavior
failures or reasons to raise a ceiling.

The final uninterrupted `npm run test:queued` backstop passed, including all 32
examples, deterministic snapshots, the 738-file Haxelib ZIP, the isolated
official-source consumer, and the gem. Separate Rails 8.1.3.1 runtime evidence,
Chromium 15/15, production 26 runs/231 assertions, all five viability workloads,
Node/Ruby advisory checks, and full-history Gitleaks over 921 commits also
passed without retry or quarantine. This delta adds one fixture to an existing
ring rather than changing test topology, so it makes no cold/warm latency or CI
speedup claim; the measured focused runtime remains roughly ten seconds on this
machine.
