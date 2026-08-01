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

- exact reproducibility for 43 active official-derived fixtures;
- explicit nonpassing status for 24 inactive official files;
- 2,248 post-macro active assertion identities;
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

- `haxe_ruby-28fa`: explain-only semantic-owner/product-surface selector and
  selector-miss observation.
- Complete shared top-level and issue corpus qualification remains later work;
  this delta does not create a false aggregate Bead or compatibility claim.
