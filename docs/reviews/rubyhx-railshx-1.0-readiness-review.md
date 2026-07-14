# RubyHx/RailsHx Stable 1.0 Readiness Review

> **Final verdict: NOT READY: P1 STABLE-RELEASE BLOCKERS**
>
> The exact reviewed commit has strong production-ready-beta evidence and a
> successful canonical CI run. No P0 stop-ship defect was found in the currently
> documented beta surface. Stable-major approval must wait until the P1 findings
> in this report are closed or removed from the public stable scope with accurate
> wording, diagnostics, and tests.

## 1. Review Baseline

| Item | Reviewed value |
| --- | --- |
| Repository | https://github.com/fullofcaffeine/reflaxe.ruby |
| Branch | main |
| Commit | 08faba040457165b883ae5327315581979ea07db (08faba0) |
| Commit subject | chore: close product thesis bead |
| Bundle date | 2026-07-13 |
| Review date | 2026-07-13 in America/Mexico_City, continuing into 2026-07-14 UTC |
| Reviewer/model | OpenAI GPT-5.6 Pro, independent repository-backed review |
| Source archive | /mnt/data/rubyhx-railshx-1.0-review-08faba0.zip |
| Archive SHA-256 | efb50794c98ba523580361722027656058c740cf64b13087a685c9223d1d7587 |
| Canonical CI | GitHub Actions run 29289643234, exact head SHA, conclusion success |
| Latest public release inspected | v0.4.0 from fef422b; the reviewed docs-only commit correctly produced no release |
| Bead snapshot | 330 issues: 326 closed, 2 open, 2 blocked; review bead haxe_ruby-kxv open |

Canonical CI: https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29289643234

### 1.1 Scope

The review covered the exact tracked source archive: product thesis, compiler and
runtime architecture, Ruby and Rails public authoring surfaces, generated
artifacts, std and gem interop, examples, CI and release machinery, security,
performance evidence, debugging evidence, compatibility policy, upgrade policy,
documentation, and ownership.

It did not implement fixes. The archive came from <code>git archive</code> and
therefore omitted Git metadata, installed dependencies, ignored outputs,
databases, caches, credentials, and the local bead database. The tracked
<code>.beads/issues.jsonl</code>, source, std facades, runtime, gem bridge,
examples, snapshots, scripts, manifests, and workflows were present.

### 1.2 Reviewer Environment

| Tool | Environment |
| --- | --- |
| OS | Linux x86_64, kernel reported as 4.4.0 |
| Node.js | v22.16.0 |
| npm | 10.9.2 |
| Ruby | 3.3.8 |
| RubyGems | 3.6.7 |
| Rake | 13.2.1 |
| Git | 2.47.3, but the archive had no .git directory |
| Java | OpenJDK 21.0.10 |
| Bundler | default gem metadata present, no bundle executable on PATH |
| Haxe | unavailable |
| bd | unavailable |

<code>npm ci --ignore-scripts --no-audit --no-fund</code> succeeded.
<code>npm audit --audit-level=high</code> found zero vulnerabilities. Installing
the locked Haxe toolchain through lix failed with DNS EAI_AGAIN. Haxe-dependent
local execution was therefore unavailable. This is an evidence limitation, not a
project test failure.

### 1.3 Evidence Classes

- **Inspected repository evidence:** source, tests, snapshots, generated
  fixtures, docs, manifests, tracked beads, and workflows read from the archive.
- **Actually run locally:** reviewer commands with recorded exit status.
- **Canonical evidence:** the successful exact-SHA GitHub Actions run and hosted
  release state. This is the primary dynamic evidence where the archive could
  not reproduce Haxe or Rails lanes.
- **Inference:** a conclusion drawn from multiple inspected facts.
- **Missing evidence:** a stable requirement for which neither the repository nor
  exact canonical run supplied proof.

### 1.4 Evidence Limits

1. Branch cleanliness and history could not be recomputed without <code>.git</code>.
   The baseline commit was matched to repository head and exact CI SHA.
2. <code>bd prime</code>, <code>bd ready</code>, and <code>bd blocked</code>
   could not run. The tracked JSONL export was inspected instead.
3. Haxe, Rails, browser, package-consumer, production, and full release
   reproducibility commands could not be rerun locally. Their exact-SHA CI jobs
   were inspected. Local unavailability is not counted as green.
4. The canonical run is strong evidence for the beta contract, but it cannot
   prove dimensions the workflow does not measure: performance, Ruby-to-Haxe
   source correlation, upgrades, rollback, and long-term maintenance ownership.

### 1.5 Maintainer Reconciliation

This report records an independent review, not an automatically accepted product
plan. Each finding must be checked against the live repository, current hosted
settings, canonical CI logs, and published release bytes before implementation
or closure. Maintainers should amend a finding when stronger local evidence
narrows, contradicts, or extends it.

The first reconciliation corrects an important support distinction: the fixture
Gemfiles accept Rails `>= 7.0` and `< 8.0`, but that dependency range does not
prove every Rails 7 minor. The committed lock and canonical beta evidence cover
Rails `7.2.3.1`; Rails 8.1 remains planned and unverified.

The maintainer reconciliation performed on 2026-07-13 also refined the initial
eight P1 findings against the live checkout, hosted repository settings, and
published `v0.4.0` release. It also reproduced one additional P1 that the
independent review missed:

| Finding | Reconciled evidence and remaining delta |
| --- | --- |
| RHX-1.0-001 | Confirmed, with the Rails range correction above. The accepted Gemfile range is not a tested support matrix. |
| RHX-1.0-002 | Confirmed for DeviseHx package paths, metadata schemas, helper owners, HHX tags, and diagnostics in core. Generic Rails route IR that can emit ordinary `devise_for` is a separate Rails capability and need not be prohibited if it no longer depends on DeviseHx vocabulary. |
| RHX-1.0-003 | Confirmed. Typed ActiveSupport duration/allocation facades and CI job durations are useful measurement inputs, but there is still no repeatable product benchmark, baseline, variance record, or regression threshold. |
| RHX-1.0-004 | Narrowed. JavaScript source maps, readable generated files, manifest output/source/SHA provenance, and `hxruby:doctor`/`check` diagnostics already exist. Manifest `source` values are generally generator-level rather than Haxe/HHX file-and-line correlation, `HxException` has no mapping layer, and the required failure journeys are not exercised. |
| RHX-1.0-005 | Narrowed and extended. Current-package isolated Haxelib and gem consumer tests already exist, and the public `v0.4.0` assets are immutable with checksum sidecars. There is still no public-asset upgrade/rollback lane. The ownership reader accepts unknown schema versions; checksum drift is diagnosed, but manifest-owned files are deliberately overwritten or deleted without a tested ownership-handoff operation. |
| RHX-1.0-006 | Narrowed. The callable ABI example is a substantive executable Ruby/Haxe interop fixture, and the package lane compiles a hello-world consumer from an isolated Haxelib repository. What is missing is one cohesive, maintained non-Rails product lifecycle rather than all pure-Ruby evidence. |
| RHX-1.0-007 | Confirmed and strengthened by live settings. Locked Ruby advisories are not scanned, `SECURITY.md` points at a removed workflow, GitHub private vulnerability reporting is disabled, and Dependabot security updates are disabled. Pinned gitleaks CI remains real evidence and should not be double-counted as absent secret scanning. |
| RHX-1.0-008 | Confirmed. No project-owned CODEOWNERS, CONTRIBUTING, GOVERNANCE, MAINTAINERS, or SUPPORT document exists. A truthful single-maintainer/best-effort policy is an acceptable outcome; a backup maintainer must not be invented. |
| RHX-1.0-009 | Newly reproduced. Generator containment was lexical: a manifest-owned output replaced by a symlink could make the shared writer overwrite a writable sibling outside the declared app root. The same shared boundary also owns forced writes, manifest writes, route extern writes, and cleanup validation. |

These refinements do not change the stable verdict. They make the implementation
work smaller and more exact, and prevent existing evidence from being rebuilt
unnecessarily.

## 2. Executive Verdict

## NOT READY: P1 STABLE-RELEASE BLOCKERS

No P0 finding was identified. Compiler, runtime, reference Rails app, packages,
browser sentinel, production build, and release controls show mature beta
engineering. The README accurately calls the project a production-ready beta,
not a stable 1.x promise.

Stable-major approval is blocked by five principal groups:

1. **The compatibility promise is not a truthful stable matrix.** Ruby 3.2 is
   advertised after upstream EOL. Rails 8 is described as supported while all
   runtime fixtures prohibit Rails 8. Rails 7.2 has a short remaining security
   window. CI omits Ruby 3.4 and Rails 8.1.
2. **Core and companion separation is violated in executable architecture.**
   Core compiler and HHX macro code recognize DeviseHx package names, schemas,
   helper owners, tags, and diagnostics despite an explicit repository invariant
   against companion-specific core knowledge.
3. **Two mandatory stable dimensions have no evidence.** There is no measured
   performance/resource baseline and no exercised production Ruby
   backtrace-to-Haxe/HHX debugging workflow.
4. **The stable public contract and upgrade path are undefined.** Release
   version selection is robust, but the project has not classified the
   SemVer-governed source, ABI, diagnostic, manifest, generator, and generated
   artifact surfaces, nor proven migration and rollback from v0.4.0.
5. **Product and operating promises exceed stable proof.** Ruby-first adoption
   and Haxe-first Rails authoring are credible. A realistic framework-independent
   Haxe-first project is not. Ruby advisory coverage, private disclosure, and
   public support ownership are also absent.

The shortest responsible path is to freeze a conservative matrix, remove the
architectural contradiction, add missing evidence lanes, define the public
contract, and narrow any claim the project chooses not to prove.

## 3. Product Thesis Assessment

### 3.1 Product Layers

The repository presents a coherent layering:

- <code>reflaxe.ruby</code> is the Haxe-to-Ruby compiler package.
- RubyHx is the framework-independent authoring and interop product layer.
- RailsHx is the Rails-native typed authoring layer on the same pipeline.
- <code>hxruby</code> is the Ruby gem bridge, runtime, and generator package.
- <code>railshx.client</code> is the generated browser-safe/shared Haxe boundary.
- DeviseHx is intended to be a companion, not an authentication runtime.

README wording correctly leaves Ruby, Rails, Bundler, gems, migrations, assets,
tests, and deployment under their native ecosystem ownership.

### 3.2 Ruby-First Adoption

**Assessment: credible and close to stable inside a frozen matrix.**

The mixed Rails fixture proves typed adoption in both directions:

- existing Ruby and ERB call generated Haxe-owned artifacts;
- Haxe calls a native Ruby constant through a precise extern;
- Haxe renders external ERB through typed locals;
- generated HHX output remains consumable from existing ERB;
- negative fixtures cover wrong locals and missing templates;
- exact canonical CI runs the Rails runtime integration across its configured
  Ruby matrix.

Allowed stable wording after matrix closure:

> RubyHx/RailsHx supports incremental adoption at typed boundaries: existing
> Ruby and ERB can call generated Ruby artifacts, and Haxe can consume existing
> Ruby services, routes, schemas, and templates through explicit typed contracts.

This does not imply safe automatic inference for arbitrary metaprogrammed gems.

### 3.3 Haxe-First RailsHx

**Assessment: substantial evidence for one bounded Rails stack, not all Rails.**

The todo application exercises ActiveRecord, controllers, typed params, routes,
migrations, HHX-to-ERB, layouts, components, Devise, Turbo Streams,
ActionCable, jobs, mailers, ActiveStorage, Rails tests, client JavaScript,
browser tests, Zeitwerk, assets, and production packaging. Canonical CI includes
full compiler/package, Rails runtime, Chromium Playwright, and production
dogfood lanes.

Allowed wording:

> RailsHx can be the primary authoring path for a Rails application using the
> documented ActiveRecord, ActionController, HHX/ActionView, Hotwire, job,
> mailer, storage, importmap/Propshaft, and generator stack.

The initial stable matrix must state the exact Rails, adapter, asset, browser,
and deployment combination guaranteed.

### 3.4 Framework-Independent Haxe-First RubyHx

**Assessment: insufficient for the current stable marketing claim.**

Hello world and callable ABI fixtures strongly prove compiler mechanics, blocks,
keywords, forwarding, method values, exceptions, and Ruby callers. They do not
prove the maintained daily workflow implied by building libraries, services, or
CLIs almost entirely in Haxe.

The missing reference project should combine a multi-file domain,
configuration, filesystem and JSON use, a Bundler-owned gem, errors, tests,
packaging or Ruby consumption, a normal edit/compile/test loop, debugging, and
upgrade/recovery. The alternative is to narrow the stable product thesis.

### 3.5 HHX

The TSX-like claim is defensible only with its supported-surface qualifier.
Recommended stable wording:

> HHX provides TSX-like typed authoring for the supported server-rendered view
> surface. It catches checked markup structure, Haxe expression types, declared
> locals, generated template, route and helper refs, and typed model and form
> fields before emitting normal ActionView ERB. HTML semantics, accessibility,
> browser behavior, dynamic Rails lookup, and application runtime behavior
> remain runtime concerns.

### 3.6 Ruby and JavaScript Sharing

The reference app proves shared typed hook names, selectors, stream contracts,
and selected pure helpers. It does not yet prove broad shared domain behavior.
Recommended wording:

> Share selected pure helpers, typed event and stream contracts, and generated
> hook and selector constants between Ruby and JavaScript while keeping
> target-specific framework code at the edges.

### 3.7 Ruby-Developer Credibility

An experienced Ruby developer is likely to accept:

- output is source Ruby, not another VM or server;
- Rails, Bundler, gems, tests, migrations, and deployment stay Ruby-owned;
- blocks, keywords, modules, concerns, and constants can stay Ruby-shaped;
- incremental typed ownership is useful for contract-heavy components;
- generated references can reduce string drift.

The same developer is likely to challenge:

- ordinary Ruby if the runtime-helper boundary is hidden;
- Rails 7+/8 when fixtures prohibit Rails 8;
- broad libraries/services/CLIs claims without a realistic project;
- broad behavior-sharing claims based mainly on hooks and selectors;
- production or stable implications without support, upgrades, advisories, and
  a debugging story.

### 3.8 Recommended Public Wording

| Current implication | Recommended wording |
| --- | --- |
| Write typed Haxe. Ship ordinary Ruby. | Write typed Haxe. Generate readable Ruby, with explicit versioned hxruby helpers where Haxe semantics require them. |
| Build libraries, services, CLIs, or Rails apps almost entirely in Haxe/HHX. | Keep the Rails claim after matrix closure. Limit pure Ruby wording to compiler and ABI foundations until a realistic project exists. |
| Share behavior, not just schemas. | Share selected pure helpers and typed contracts across Ruby and JavaScript; keep target-specific framework code at the edges. |
| Rails 7+/8 style app shape. | Publish exact tested versions and dated support policy. Do not use a plus sign as a support promise. |
| Ruby 3.2, 3.3, and 4.0. | Remove Ruby 3.2, add 3.4, and give 3.3 an explicit sunset if retained. |
| Production-ready without qualifier. | Keep production-ready beta for the documented and tested surface until all P1s close. |

## 4. Architecture Assessment

### 4.1 High-Level Map

~~~
Haxe source and typed macros
        |
        v
Haxe compiler typed AST
        |
        v
Vendored Reflaxe 4.0.0-beta
        |
        v
src/reflaxe/ruby/RubyCompiler.hx
  |-- ruby_first and portable semantic profiles
  |-- Ruby AST, lowering, naming, callable ABI, diagnostics
  |-- Rails artifact, lifecycle, query, view, route, migration, and test lowering
  |
  +--> std/ruby and std/ruby/_std --> native facades and Haxe parity adapters
  +--> runtime/hxruby             --> explicit Haxe-semantics helpers
  +--> std/rails and macros       --> Rails-native Ruby, ERB, routes, migrations
  +--> lib/hxruby                 --> gem bridge, generators, tasks, manifests
  +--> std/devisehx               --> intended companion layer

Shared/client Haxe
        |
        +--> normal Haxe -js typing plus Genes final emitter
                |
                +--> split ES modules plus importmap and Propshaft ownership
~~~

This is one compiler pipeline. <code>ruby_first</code> and
<code>portable</code> are semantic contracts, not separate engines.
<code>idiomatic</code> is a compatibility alias.

### 4.2 Component Inventory

| Component | Approximate size | Role |
| --- | ---: | --- |
| src/reflaxe/ruby | 29 files, 20,257 lines | Compiler, Ruby lowering, macros, Rails services |
| RubyCompiler.hx | 15,038 lines, about 829 function declarations | Reflaxe entrypoint plus substantial target and Rails orchestration |
| std/ruby | 40 files, 2,011 lines | Ruby facades and Haxe-semantic adapters |
| std/rails | 149 files, 10,033 lines | Typed Rails authoring surface |
| std/devisehx | 24 files, 824 lines | Devise companion surface |
| runtime/hxruby | 4 files, 956 lines | Haxe semantic runtime support |
| lib/hxruby | 26 files, 8,384 lines | Gem bridge, Rails tasks, generators, ownership |
| scripts/ci | 82 files, 30,406 lines | Static, compile, runtime, package, browser, release gates |
| test | 363 files, 34,432 lines | Compiler, snapshot, negative, runtime, Rails, generator fixtures |

The root compiler remains a P2 maintainability risk. Its size alone is not a
stable blocker because behavior has strong characterization coverage. The
companion-specific leakage is P1 because it contradicts a public architecture
invariant and expands core's accidental compatibility surface.

### 4.3 DeviseHx Boundary Violation

Repository guidance says core must not couple to third-party or companion names.
The implementation contradicts this:

- <code>RubyCompiler.hx:1301-1369</code> recognizes
  <code>:deviseHxRoute</code>.
- <code>RubyCompiler.hx:2257-2377</code> contains a Devise-specific strict
  current-user define, flow diagnostics, and owner checks.
- <code>RubyCompiler.hx:2668-2709</code> validates Devise module tokens.
- <code>RubyCompiler.hx:3750-3884</code> parses Devise helper schemas and
  dispatches DeviseHx owners.
- <code>RubyCompiler.hx:13858-13920</code> recognizes DeviseHx HHX helpers.
- <code>RubyCompiler.hx:14324-14350</code> emits DeviseHx schema diagnostics.
- <code>RailsInlineMarkup.hx:1306-1322</code> has first-class Devise tags.
- <code>RailsInlineMarkup.hx:1384-1399</code> dispatches Devise route helpers.

Closed bead <code>haxe.ruby-67c</code> already records the remaining debt and
recommends a generic companion registry. Current tests prove the special case
works; they do not make the extension architecture generic.

### 4.4 Runtime Ownership

Runtime ownership is explicit and package tests require the helper files in both
release artifacts. Helpers cover Haxe string, array, math, type, reflection,
enum, and exception semantics. The honest contract is readable Ruby plus
explicit helpers where parity requires them.

Stable 1.x must either version every generated-code-called runtime helper as an
ABI or bundle compiler and runtime atomically with a clear mismatch failure.

### 4.5 Vendored Reflaxe

Vendored Reflaxe provenance is documented, including the lazy function-field
patch from commit 024937acffd242f129265d969a840d3779f02bcd, a focused regression,
packaging checks, and a removal rule. This is acceptable for 1.0 if the exact
vendor baseline remains part of the support manifest.

### 4.6 Client Boundary

Browser builds use <code>railshx.client</code>; Haxe performs normal JavaScript
typing and Genes emits split ES modules for Rails importmap and Propshaft. The
stable promise must scope this to the tested Genes, importmap, Propshaft, and
Chromium path unless additional lanes are added.

### 4.7 Generator Ownership

Generator safety is strong:

- generated files receive an ownership header;
- non-owned files are not overwritten without force;
- output paths stay within the root;
- manifest entries record SHA-256;
- clean removes only manifest-owned outputs.

The versioned upgrade contract is incomplete. The manifest reader accepts an
unknown version and treats a missing version as current. Stable readers must
reject unknown-newer schemas and migrate older supported schemas with backups,
idempotence, and rollback.

## 5. Public Surface Inventory

The absence of a formal SemVer classification is finding RHX-1.0-005.

### 5.1 Product and Package Identities

| Surface | Role | Proposed 1.x treatment |
| --- | --- | --- |
| reflaxe.ruby | Compiler, std, vendored framework, runtime assets | Public package name and layout |
| RubyHx | Framework-independent product layer | Public product and API scope |
| RailsHx | Typed Rails authoring layer | Public only inside exact Rails matrix |
| hxruby | Runtime bridge, tasks, generators, client package | Public package, runtime ABI, commands, schema |
| railshx.client | Browser-safe/shared library boundary | Public for documented asset stack |
| devisehx | Companion contract | Separate lifecycle; no core internals |
| npm package | Private repo orchestration | Maintainer-only surface |

### 5.2 Profiles and Defines

Public profile inputs include:

- <code>reflaxe_ruby_profile=ruby_first</code>;
- <code>reflaxe_ruby_profile=portable</code>;
- default <code>ruby_first</code>;
- compatibility aliases <code>idiomatic</code>, <code>ruby_first</code>,
  <code>ruby_idiomatic</code>, and <code>ruby_portable</code>.

Public-in-effect compiler and build defines include:

- <code>ruby_output</code>;
- <code>reflaxe_runtime</code>;
- <code>reflaxe_ruby_profile</code>;
- <code>reflaxe_ruby_rails</code>;
- <code>reflaxe_ruby_rails_output_root</code>;
- <code>reflaxe_ruby_strict</code>;
- <code>railshx_allow_unchecked_routes</code>;
- <code>railshx_devise_strict_current_required</code>, currently architecturally
  misplaced;
- <code>rails_hxx_no_inline_markup</code>, which needs explicit classification.

Repository-only policy defines such as
<code>reflaxe_ruby_strict_examples</code> should not accidentally become public.
Future optimization ideas documented in profiles are not implemented guarantees.

### 5.3 Metadata

Documented public Ruby metadata:

- <code>@:native</code>, <code>@:rubyRequire</code>,
  <code>@:rubyRequireRelative</code>, <code>@:rubyKwargs</code>,
  <code>@:rubyBlockArg</code>;
- <code>@:rubyMixin</code>, <code>@:rubyInclude</code>,
  <code>@:rubyPrepend</code>, <code>@:rubyExtend</code>,
  <code>@:rubyExtensionOverride</code>, <code>@:rubyPatch</code>,
  <code>@:rubyModule</code>, <code>@:rubyConcern</code>;
- <code>@:rubyNoEmit</code>, <code>@:rubyAllowRaw</code>.

Documented public Rails artifact metadata includes application controller,
controller, external controller, model, timestamps, columns, external
attributes, enums, callbacks, scopes, migrations, routes, template, template
AST, raw ERB escape, mailer, job, channel, cable connection, and test metadata.

Internal handoff markers such as injected extension, association, attachment,
field, filter, cable, no-emit, and HHX parser sentinels should be explicitly
excluded from compatibility guarantees. Public macro-level associations,
validations, callbacks, attachments, and lifecycle DSLs still belong in the
generated public-surface manifest even when normalized to internal metadata.

### 5.4 Commands, Runtime, and Generated Formats

End-user public-in-effect commands include the generated app
<code>hxruby:*</code> compile, client compile, watch, Rails, database, test,
start, routes, doctor, check, clean, production, and generator tasks.

The runtime ABI includes iterator, stringification, JSON, numeric parsing,
UTF-16 string behavior, StringTools behavior, arrays, math, type and enum,
reflection, constant resolution, <code>HxException</code>, and
<code>Data.define</code> compatibility.

Public-in-effect generated formats include:

- Ruby source and prelude requires;
- Rails models, controllers, jobs, mailers, channels, and connection code;
- ERB emitted from HHX;
- routes, manifests, externs, and timestamped migrations;
- generated Minitest or RSpec artifacts;
- split JavaScript modules and importmap integration;
- runtime files and Rails initializer;
- <code>.railshx/manifest.json</code> schema version 1;
- the RailsHx ownership header;
- Haxelib-compatible ZIP, gem, checksum, and provenance assets.

Exact snapshot bytes should not make incidental formatting public API. Stable
1.x should distinguish behavioral and callable ABI from private formatting.

## 6. Claim-Evidence Matrix

| Claim | Proof | Limit | Confidence | Allowed wording now | Stable follow-up |
| --- | --- | --- | --- | --- | --- |
| Typed Haxe generates readable Ruby | Snapshots, syntax checks, runtime fixtures, callable ABI, exact CI | Haxe parity uses explicit runtime helpers | High | Generates readable Ruby plus explicit helpers where required | Freeze runtime ABI and debugging contract |
| Unsupported lowering fails closed | Negative diagnostics, strict boundaries, correctness docs | Haxe could not run locally | High | Documented supported lowering fails closed in tested fixtures | RC rerun and stable diagnostic IDs |
| Ruby naturally calls generated code | Callable ABI covers constants, blocks, kwargs, forwarding, exceptions | Not every metaprogrammed shape | High | Documented callable ABI uses native Ruby shapes | SemVer classification and upgrade test |
| Ruby-first Rails adoption works | Mixed app, external ERB, externs, negative and request tests | One reference architecture | High | Incremental typed boundaries are supported for documented contracts | Final matrix and unsupported seams |
| Rails app can be Haxe-first | Todo app static, runtime, browser, production | Rails 7.2, SQLite, importmap, Propshaft, Genes, Chromium only | High for that stack | Haxe/HHX can own most source on the documented reference stack | Exact matrix or RailsHx remains beta |
| Library, service, or CLI can be Haxe-first | Hello and ABI examples | No realistic lifecycle fixture | Low | RubyHx provides compiler and ABI foundations | Add project or narrow marketing |
| HHX gives TSX-like server views | Typed markup, locals, helpers, refs, snapshots, negatives | Runtime HTML, accessibility, auth, and browser behavior | High | Use the bounded wording in section 3.5 | Keep claim matrix and RC tests |
| Ruby/JavaScript behavior can be shared | Hooks, selectors, contracts, selected helpers, client build | No substantial domain parity proof | Medium | Share selected pure helpers and contracts | Add two-target domain fixture or narrow |
| Rails 7+/8 supported | Compatibility prose | Gemfiles require Rails below 8; no Rails 8 lane | Low | Current beta fixtures run Rails 7.2.3.1 | Exact supported Rails line |
| Ruby 3.2/3.3/4.0 supported | Exact CI passes those branches | 3.2 EOL; 3.4 absent | Medium historically, low as stable support | Reviewed beta CI ran this matrix | Remove 3.2, add 3.4, sunset 3.3 |
| Releases bind exact SHA | Version, artifact, workflow, immutable v0.4.0 evidence | Archive could not rerun Git-dependent reproduction | High | Current protocol binds assets to tested commit | RC exact-SHA rerun |
| Security is production-oriented | Escape policies, npm audit, gitleaks, pinned actions | No Ruby advisory scan; vague disclosure | Medium | Escape, npm, secret, and release controls are gated | Close RHX-1.0-007 |
| Production failures are diagnosable | Source diagnostics, readable output, JS maps | Ruby backtrace mapping explicitly unimplemented | Low | Generated Ruby is inspectable; Haxe source correlation is not stable | Close RHX-1.0-004 |
| Project is production-ready | Exact CI and broad beta evidence | Stable matrix, performance, debug, upgrades, ownership missing | High for beta | Production-ready beta for tested surface | Close or scope all P1s |
| Project is ready for stable 1.0 | Stable criteria exist | Multiple mandatory dimensions missing | High confidence that claim is disallowed | Do not make this claim | Complete blockers and independent RC review |

## 7. Stable-Readiness Scorecard

| # | Dimension | Status | Confidence | Release consequence |
| ---: | --- | --- | --- | --- |
| 1 | Product goals and market credibility | PARTIAL | High | Pure-Ruby workflow or claim correction required |
| 2 | Architecture and ownership | PARTIAL | High | Companion extraction required; modularity follows |
| 3 | Compiler correctness and semantics | PROVEN for beta surface | High | Rerun on final matrix |
| 4 | Generated Ruby and runtime behavior | PARTIAL | High | Runtime ABI and source correlation undefined |
| 5 | Ruby stdlib, gems, native interop | PARTIAL | High | Keep claim scoped; catalog remains P2 |
| 6 | Rails depth and native semantics | PARTIAL | High | Exact Rails and adapter matrix required |
| 7 | Public API and developer experience | PARTIAL | High | API tiers, diagnostics, deprecation missing |
| 8 | Haxe-first, adoption, ecosystem integration | PARTIAL | High | Pure-Ruby workflow missing |
| 9 | Ruby/JavaScript sharing | PARTIAL | Medium-high | Deepen or narrow wording |
| 10 | Testing and release evidence | PARTIAL | High | Performance, debug, and upgrade lanes missing |
| 11 | Security and supply chain | PARTIAL | High | Ruby advisories and disclosure required |
| 12 | Performance and resource behavior | MISSING | High | P1 stable blocker |
| 13 | Debugging and observability | MISSING | High | P1 stable blocker |
| 14 | Compatibility, packaging, upgrades | PARTIAL | High | Matrix, public surface, migration, rollback required |
| 15 | Documentation, onboarding, maintenance | PARTIAL | High | Pure-Ruby journey and support ownership required |

No dimension is outside documented scope because the repository's own stable
definition includes all fifteen. Breadth can be narrowed, but the dimensions
cannot be silently waived.

## 8. Findings

### P0

**None found.** The exact canonical workflow passed and no known silently wrong
code, data loss, critical/high unpatched security defect, or release-integrity
defect was identified inside the current beta scope. This does not imply complete
semantic correctness.

### P1: RHX-1.0-001 - Truthful Stable Support Matrix

**Tracked as:** <code>haxe_ruby-huf</code>

**Impact:** Users cannot distinguish actively supported combinations from ones
that merely passed once or are outside upstream maintenance.

**Evidence:**

- README advertises Ruby 3.2, 3.3, and 4.0.
- CI runs those versions and omits Ruby 3.4.
- compatibility prose says Rails 7+/8 style.
- todo and interop Gemfiles require Rails below 8 and resolve 7.2.3.1.
- browser and production run only on Ruby 3.3.
- Ruby 3.2 reached upstream EOL on 2026-04-01.
- Rails 7.2 security support ends 2026-08-09; 8.0 ends 2026-11-07;
  8.1 ends 2027-10-10.

**Required outcome:** Commit one dated, machine-readable matrix covering Haxe,
Ruby, Rails, Node, OS/architecture, database, browser, asset stack, package
channel, and sunsets. Align README, docs, package metadata, generated app
templates, Gemfiles, and CI. Remove Ruby 3.2, add Ruby 3.4, and either add Rails
8.1 runtime evidence or keep RailsHx out of the stable claim.

**Acceptance evidence:**

1. A support manifest is checked against every public and executable surface.
2. Full compiler, package, and Rails runtime gates pass for every supported pair
   at the exact RC SHA.
3. Browser and production cover primary and oldest pairs, or a documented
   representative-only risk policy.
4. Node is tested at the declared minimum and latest supported patch.
5. Unsupported combinations fail with actionable diagnostics.
6. Calendar-based EOL review prevents stale advertised branches.

**Scope alternative:** Stabilize RubyHx only on Ruby 3.4/4.0 and keep RailsHx
beta until Rails 8.1 passes.

### P1: RHX-1.0-002 - Generic Companion Contract

**Tracked as:** <code>haxe_ruby-8q9</code>

**Impact:** Stable core currently depends on one companion's paths, schema,
helper vocabulary, tags, and diagnostics, coupling cadence and making other
companions second class.

**Required outcome:** Define a typed, versioned companion contract for metadata
or IR contributions, helper lowering, HHX component expansion, inventory
validation, diagnostics, package/runtime requirements, and test integration.
Move all DeviseHx package-specific knowledge into the companion or generator
layer. Core may retain generic Rails routing concepts that emit `devise_for`
only when their input contract no longer names or requires DeviseHx.

**Acceptance evidence:**

1. A core guard rejects DeviseHx package names, type paths, schemas, and helper
   owners outside explicit architecture fixtures; it does not confuse ordinary
   Rails `devise_for` output with companion-package coupling.
2. Existing Devise snapshots, negative diagnostics, runtime, HHX, routes,
   current-user flow, package, and todoapp gates pass.
3. Public docs and a minimal fake companion prove genericity.
4. Core compiles and packages without DeviseHx present.

**Scope alternative:** Remove DeviseHx from the stable package and reference
scope until extraction. Core package checks still need isolation.

### P1: RHX-1.0-003 - Performance and Resource Baselines

**Tracked as:** <code>haxe_ruby-0ss</code>

**Impact:** Teams cannot estimate build-loop cost, output growth, boot/request
overhead, runtime-helper cost, or client impact. Maintainers cannot identify
material regressions.

**Evidence:** The stable criteria require compile time, runtime, startup, memory
or allocation, artifact size, production behavior, and regression policy.
Repository inspection found no benchmark command, baseline, threshold file,
trend report, or CI performance lane. Typed ActiveSupport instrumentation exposes
duration and allocation values, but no maintained workload currently turns
those primitives into a RubyHx/RailsHx baseline.

**Required outcome:** Add reproducible cold and warm/incremental compile,
artifact-size, Rails boot, representative request/job, memory/allocation, and
client-output measurements with pinned runner metadata.

**Acceptance evidence:**

1. One documented command emits machine-readable and human results.
2. Immutable RC baselines record workload and runner metadata.
3. At least three samples establish variance.
4. CI blocks unexplained material regressions with reviewed baseline updates.
5. Public numbers remain workload-scoped.

**Scope alternative:** Make no speed claim and publish only a minimal viability
baseline. The dimension itself cannot be omitted under current exit rules.

### P1: RHX-1.0-004 - Production Debugging and Source Correlation

**Tracked as:** <code>haxe_ruby-9dm</code>

**Impact:** A Ruby backtrace, Rails request/job failure, generated ERB line, or
browser error may not identify the owned Haxe/HHX source.

**Evidence:** Compile diagnostics and generated source are strong. JavaScript
has source maps. The ownership manifest records output paths, generator-level
source labels, and SHA-256, while <code>hxruby:doctor</code> checks manifest
drift plus route and migration state. Those are coarse provenance and diagnostic
foundations, not Haxe/HHX line correlation. <code>HxException</code> does not map
Ruby backtraces, the stdlib audit says Ruby CallStack mapping must be designed,
and no maintained failure journey covers generated Ruby, Rails, HHX/ERB, or
production assets.

**Required outcome:** Choose either Haxe source maps, a generated-to-owned-source
manifest, or an explicit deterministic generated-Ruby debugging contract, and
exercise it end to end.

**Acceptance evidence:**

1. Fixtures trigger compile, generated Ruby load, Haxe-origin Ruby exception,
   Rails request, ActiveJob, HHX/ERB, browser, and production asset failures.
2. Each locates the responsible Haxe/HHX or explicitly supported generated
   source through documented commands.
3. Doctor/check reports compiler/runtime mismatch and provenance.
4. Exception wrapping preserves cause and backtrace behavior.
5. Logging examples preserve correlation without leaking secrets.

**Scope alternative:** State that generated Ruby/ERB is the supported debug
source, provided paths and lines are deterministic and the workflow is tested.

### P1: RHX-1.0-005 - Public Contract, Deprecation, Upgrade, Rollback

**Tracked as:** <code>haxe_ruby-i1g</code>

**Impact:** Users cannot know which metadata, defines, profiles, diagnostics,
callable ABI, runtime helpers, commands, schemas, paths, and generated artifacts
are stable, nor rehearse an upgrade or rollback.

**Evidence:** Stable-major version approval is robust. Metadata and profiles are
already described as public. Current-package tests build and install isolated
Haxelib and gem consumers, and the hosted <code>v0.4.0</code> ZIP and gem are
immutable with checksum sidecars. No complete compatibility classification,
deprecation window, or public-v0.4.0-to-RC project fixture exists. Unknown
manifest versions are accepted. Manifest checksums produce drift diagnostics,
but documented manifest ownership still permits rewrite and clean without a
defined, tested operation for transferring a changed file back to app ownership.

**Required outcome:** Publish a machine-checked public-surface manifest and 1.x
policy. Define source, callable/runtime ABI, artifact schema, diagnostics,
ownership, compiler/runtime compatibility, deprecation, migration, and rollback.

**Acceptance evidence:**

1. Public-surface inventory is generated and checked.
2. Patch, minor, major, and internal changes are classified.
3. Deprecations have stable IDs, replacements, and a removal window.
4. Immutable v0.4.0 pure-Ruby and Rails projects upgrade to an RC and roll back.
5. Unknown-newer manifests fail before overwrite or deletion; old supported
   schemas migrate with backup and idempotence.
6. Compiler/runtime mismatch fails clearly.
7. Drifted generated files have an explicit contract: either mutations fail
   closed until regeneration/force, or disposable output remains allowed with a
   documented and tested command that safely removes manifest/header ownership
   when a user takes the file back.

**Scope alternative:** Exclude private formatting and helper internals while
guaranteeing documented source APIs, callable/runtime ABI, paths, and ownership.

### P1: RHX-1.0-006 - Realistic Pure-Ruby Haxe-First Project

**Tracked as:** <code>haxe_ruby-1u1</code>

**Impact:** A Haxe-first adopter may choose RubyHx for a library, service, or CLI
without a maintained workflow for project layout, gems, tests, packaging,
debugging, or upgrades outside Rails.

**Existing foundation:** <code>examples/ruby_callable_abi</code> exercises a
typed stdlib boundary and handwritten Ruby caller with snapshots and runtime
tests. The Haxelib package check also installs the freshly built archive into an
isolated repository, compiles an external hello-world consumer, and runs its
Ruby output. These are valuable components, but not yet one realistic product
lifecycle.

**Required outcome:** Maintain one representative non-Rails product, preferably
a small library plus CLI or service. Keep nearly all owned source in Haxe while
using Bundler and at least one Ruby gem through a typed boundary. Include config,
filesystem/JSON, errors, tests, a Ruby consumer, packaging or deployment,
normal edit loop, debugging, and upgrade/rollback.

**Acceptance evidence:**

1. Fixture installs only public release assets.
2. Guide goes from empty directory to compile, run, test, package, and consume
   without editing generated Ruby.
3. Negative compile and Ruby runtime tests cover typed gem and error behavior.
4. CI runs the full stable Ruby matrix.
5. The project participates in the upgrade/rollback lane.

**Scope alternative:** Remove stable libraries/services/CLIs wording and
stabilize only compiler/callable ABI plus Rails and incremental adoption.

### P1: RHX-1.0-007 - Ruby Advisories and Security Disclosure

**Tracked as:** <code>haxe_ruby-qrt</code>

**Impact:** Users lack Ruby dependency advisory evidence and an actionable
private reporting route. Stale security docs can misdirect reporters.

**Evidence:** npm audit, gitleaks, escape-hatch controls, path controls, pinned
actions, and exact-SHA release security are strong. No bundler-audit, Ruby
Advisory Database, OSV, or equivalent locked-gem scan was found.
<code>SECURITY.md</code> says only to report privately to the owner and names a
workflow that no longer exists. Live repository settings on 2026-07-13 reported
private vulnerability reporting and Dependabot security updates disabled. The
custom full-history gitleaks lane remains valid secret-scanning evidence even
though GitHub's hosted secret-scanning switches are disabled.

**Required outcome:** Add mandatory advisory scanning for locked project and
reference-app Ruby dependencies. Publish a usable private channel, supported
security versions, truthful acknowledgement and update expectations,
coordinated disclosure, and an emergency release path.

**Acceptance evidence:**

1. CI scans npm and locked Ruby dependencies through maintained sources.
2. A fixture proves detection of a known vulnerable lock entry.
3. A monitored private channel is documented and operationally checked.
4. Security docs name supported versions, process, and sustainable expectations.
5. Generated apps inherit appropriate security/update guidance.

**Scope alternative:** Use a community-supported, best-effort contract while
still scanning dependencies shipped or locked by the project.

### P1: RHX-1.0-008 - Maintenance and Support Ownership

**Tracked as:** <code>haxe_ruby-9xsp</code>

**Impact:** Stable adopters cannot tell who owns releases, security,
compatibility, dependency updates, issue triage, companions, or sunsets.

**Evidence:** The readiness contract requires public maintenance ownership.
There is no CODEOWNERS, CONTRIBUTING, GOVERNANCE, MAINTAINERS, or SUPPORT
document. Security wording uses an ambiguous repository owner placeholder.

**Required outcome:** Publish release, security, compatibility, dependency,
triage, documentation, and companion roles; channels; version/EOL policy;
decision process; best-effort expectations; and backup/recovery rules for
privileged operations.

**Acceptance evidence:**

1. Public docs name roles and channels without ambiguous placeholders.
2. Runbooks identify backup authority or disclose and mitigate single-maintainer
   risk.
3. Compatibility changes and stable-major approval require recorded review.
4. Dependency and support-version review is part of the release checklist.
5. Core versus companion issue routing is clear.

**Scope alternative:** Publish an honest single-maintainer, best-effort,
community-supported contract with no response SLA.

### P1: RHX-1.0-009 - Generator Output Symlink Containment

**Tracked as:** <code>haxe_ruby-08b2</code>

**Impact:** A malicious or stale local manifest/output pair can redirect a
generator write outside the declared app root to any file writable by the
generator process. This requires local repository state or filesystem control;
no remote execution path was identified.

**Evidence:** The shared writer checked only the expanded lexical prefix before
following an existing output path with <code>File.write</code>. A temporary
reproduction placed a manifest-owned symlink under the app root, ran
<code>Common.write_file</code> without force, and observed the sibling target
change from <code>before</code> to <code>after</code>. Existing docs claimed
symlink escapes were rejected, so this is an implementation/claim mismatch the
independent archive review did not catch.

**Required outcome:** Canonicalize existing output ancestors against the
declared root, reject symlink leaves even for manifest-owned and forced writes,
use no-follow file creation where available, protect the manifest itself, and
validate all cleanup targets before the first deletion. Apply the same boundary
to atomic route extern generation.

**Acceptance evidence:**

1. Focused tests reproduce and reject manifest-owned and forced symlink leaves.
2. A symlinked parent cannot redirect a new output outside the root.
3. A symlinked ownership manifest cannot redirect manifest writes.
4. Cleanup rejects unsafe paths before deleting any safe output.
5. Normal in-root generation, rewrite, manifest recording, and cleanup pass.

**Scope alternative:** None for stable. A generator advertised as fail-closed
cannot knowingly permit outside-root writes.

### P2: RHX-1.0-101 - Continue RubyCompiler Decomposition

**Tracked as:** <code>haxe_ruby-e2ba</code>

Keep the Reflaxe root while moving coherent Rails view, route, migration,
lifecycle, test, companion, and artifact services behind typed interfaces.
Add architecture guards and characterization tests. The Devise-specific portion
is owned by RHX-1.0-002 and must not be duplicated here.

### P2: RHX-1.0-102 - Deepen or Narrow Shared Behavior

**Tracked as:** <code>haxe_ruby-r0h0</code>

Either add a substantive shared pure-domain validation, state-transition, or
serialization module with identical Ruby and JavaScript vectors, or permanently
narrow wording to contracts, constants, hooks, selectors, and small pure
helpers.

## 9. Test and Evidence Map

### 9.1 Commands Attempted Locally

<code>FAIL (environment)</code> below means no product evidence was produced
because the archive lacked the executable, Git metadata, or Haxe/Rails
toolchain. It is not a failing project gate.

| Command | Exit | Result |
| --- | ---: | --- |
| bd prime | 127 | bd unavailable |
| bd ready | 127 | bd unavailable |
| bd blocked | 127 | bd unavailable; tracked JSONL inspected |
| git status --short --branch | 128 | no .git in archive |
| git log --oneline --decorate -30 | 128 | no .git in archive |
| npm test | 1 | release-policy subgates passed; reproducibility required Git |
| npm run test:examples-compile | 244 | Haxe absent; lix download failed DNS |
| npm run test:unitstd-ruby | 1 | Haxe compile unavailable |
| rake test:rails:runtime | 1 | stopped at Haxe compile |
| rake todoapp:playwright | 1 | stopped during Haxe app prepare |
| rake todoapp:production | 1 | stopped at missing Haxe |
| rake test:snapshots | 1 | Haxe download failed |
| rake test:strict_boundaries | 1 | compiler could not start |
| rake test:sql_string_policy | 0 | PASS |
| rake package:haxelib:test | 1 | Git identity and Haxe unavailable |
| rake package:gem:test | 1 | Git, Haxe, and Bundler unavailable |
| rake ci:release_contracts | 1 | static checks passed; reproduction required Git |
| rake security:gitleaks | 1 | full-history scan required Git |

### 9.2 Additional Local Evidence

| Check | Result |
| --- | --- |
| npm ci --ignore-scripts --no-audit --no-fund | PASS, 315 packages |
| npm audit --audit-level=high | PASS, zero vulnerabilities |
| Ruby syntax across 271 Ruby/Rake/gemspec files | PASS |
| node --check across 104 JS/MJS/CJS files | PASS |
| JSON parse across 18 files | PASS |
| YAML parse across 6 files | PASS |
| npm run ci:version-sync | PASS |
| npm run test:release-version-policy | PASS |
| npm run test:release-workflow | PASS, 10 cases |
| npm run test:release-hosting | PASS, 12 states |
| npm run test:compiler-metadata-docs | PASS |
| npm run test:stdlib-inventory | PASS |
| npm run test:gap-report | PASS |
| npm run test:sql-string-policy | PASS |

A synthetic Git repository was used only to inspect static release scripts. It
was not the reviewed commit and is not release provenance.

### 9.3 Exact Canonical CI

The exact reviewed SHA passed run 29289643234.

| Job | What it proves | What it does not prove |
| --- | --- | --- |
| Locked dependency and secret audit | npm install/audit, full-history gitleaks, pinned actions | Ruby advisories and disclosure operations |
| Haxe formatter | Haxe 4.3.7 format gate | Runtime behavior |
| Full suite on Ruby 3.2/3.3/4.0 | Compiler, snapshots, negatives, unitstd, Rails static/generators, packages | Future versions, Rails 8, performance, debug, upgrades |
| Rails runtime on Ruby 3.2/3.3/4.0 | Controller, params, mailer, job, storage, cable, mixed interop | Non-SQLite adapters, Rails 8, all Rails APIs |
| Browser sentinel on Ruby 3.3 | Chromium, client, Hotwire reference flow | Other browsers, versions, asset stacks |
| Production dogfood on Ruby 3.3 | Tests, boot, assets, package path | Resource behavior and hosts |
| Release contracts | Version, artifact, exact-SHA protocol | User upgrade and rollback |
| Release exact CI-tested commit | All declared jobs gate publication at github.sha | Stable API fitness |

## 10. Proposed Initial Stable Matrix

This is a target for an RC, not a claim about the reviewed commit.

| Axis | Proposed 1.0 contract |
| --- | --- |
| Haxe | Exactly 4.3.7 for 1.0.0 |
| Reflaxe | Vendored 4.0.0-beta baseline plus recorded exact patches |
| MRI Ruby primary | 3.4 and 4.0 at latest security patches |
| MRI Ruby transitional | Optional 3.3 with sunset no later than upstream EOL |
| Rails primary | Rails 8.1 latest security patch, one bounded minor line |
| Rails transitional | None by default; add 7.2 or 8.0 only with explicit short sunset |
| Node | Test declared minimum and latest patch in one supported line; decide 22 versus 24 deliberately |
| npm | 10.9.2 for deterministic repository and release jobs |
| OS and architecture | Ubuntu 24.04, Linux x86_64 |
| Ruby implementation | MRI only |
| Database runtime | SQLite |
| Database compile-only | PostgreSQL and MySQL only if clearly labeled |
| Client stack | importmap-rails, Propshaft, Turbo, pinned Genes, railshx.client |
| Browser | Current Chromium through pinned Playwright |
| Rails test adapter | Minitest runtime; classify RSpec separately |
| Authentication | DeviseHx only after generic companion extraction and its own matrix |
| Distribution | Verified GitHub Release ZIP and gem assets plus sidecars |
| Deployment | Reference production build, boot, and assets; no provider promise |

A smaller coherent option is RubyHx stable on Ruby 3.4/4.0 with RailsHx still
beta until Rails 8.1 support lands.

### 10.1 Explicit Exclusions

Initial 1.0 docs should exclude unless evidence is added:

- Ruby 3.2 and other EOL branches;
- broad Rails 7+ or arbitrary-major compatibility;
- JRuby, TruffleRuby, Windows, macOS, ARM, and Alpine/musl;
- PostgreSQL/MySQL production runtime guarantees;
- all Ruby stdlib/default/bundled gems and arbitrary metaprogrammed gems;
- automatic precise adoption where metadata cannot prove a contract;
- all Rails APIs, asset stacks, ORMs, test frameworks, and companions;
- stock Haxe JavaScript emitter compatibility for the reference app;
- non-Chromium browser guarantees;
- Haxelib or RubyGems.org registry availability;
- Haxe-level Ruby source maps unless RHX-1.0-004 proves them;
- exact private generated formatting as public API;
- comparative performance claims;
- arbitrary isomorphic application behavior;
- commercial SLA or long-term support beyond the published policy.

## 11. SemVer and Upgrade Recommendation

### 11.1 Surface Tiers

1. **Tier A: public source and command contract.** Package names, install
   entrypoints, public imports, profiles and aliases, documented defines,
   metadata and DSL signatures, end-user tasks and flags, ownership rules, and
   verification commands.
2. **Tier B: callable and runtime ABI.** Ruby constants, methods, blocks,
   keywords, exceptions consumed by handwritten Ruby; runtime loading path; all
   helper names called by generated code; compiler/runtime compatibility marker.
3. **Tier C: versioned artifact schemas.** Ownership manifest, routes, schema
   and inventory contracts, companion registration, provenance, and any source
   correlation maps. Readers reject unknown-newer versions.
4. **Tier D: diagnostic contract.** Stable identifiers, severity, source
   positioning, and remediation category. Exact prose may improve.
5. **Internal.** Compiler-private functions, handoff metadata, incidental
   formatting, vendored layout internals, CI script names, and private generated
   locals.

Generated Ruby should be readable and behaviorally stable without freezing all
textual output.

### 11.2 Change Classification

| Change | 1.x treatment |
| --- | --- |
| Correct wrong or unsafe behavior within documented contract | Patch with regression; migration note if output changes |
| Add optional typed API or metadata | Minor |
| Tighten documented-unsupported unsafe input | Patch or minor based on impact, with stable diagnostic |
| Remove or rename Tier A/B/C surface | Major unless compatibility or migration preserves behavior |
| Change supported ruby_first or portable semantics | Major except documented correctness fix |
| Change private whitespace or locals | Internal or patch |
| Add supported tool/runtime version | Minor after matrix evidence |
| Drop version before sunset | Major or documented security exception |
| Drop at preannounced sunset | Minor if policy reserves it and notice was met |
| Incompatible schema reader | Major unless automatic migration handles old state |

### 11.3 Deprecation

- Keep deprecated Tier A/B surfaces functional for at least two minor releases
  and 90 days, whichever is longer, except urgent security removal.
- Emit a stable diagnostic code, replacement, and removal target.
- Keep <code>idiomatic</code> and short profile aliases throughout 1.x unless a
  compelling reason is independently approved.
- Document security exceptions, migration, and affected versions.
- Publish a public-surface diff and migration notes with every minor release.

### 11.4 Upgrade and Rollback

Before stable approval, pure-Ruby and Rails release-consumer fixtures should:

1. install the exact checksum-verified v0.4.0 Haxelib ZIP and `hxruby` gem
   from the public GitHub Release, without repository-relative dependencies or
   locally rebuilt substitutes;
2. compile, test, and run;
3. upgrade to the exact RC package pair;
4. dry-run ownership/schema migration;
5. back up manifest and generated ownership state;
6. regenerate, compile, test, and run browser/production where applicable;
7. prove handwritten Ruby/ERB and database state are preserved;
8. roll package and generated state back;
9. compile, test, and run again;
10. prove unknown-newer schema and compiler/runtime mismatch fail before
    destructive actions.

Hosted release repair is valuable but solves a different problem from user
project migration.

## 12. Path from Beta to Stable

### Phase 0: Product and Support Decisions

- answer the owner questions below;
- commit one stable matrix;
- remove Ruby 3.2 and unproven Rails 8 wording;
- approve public surface tiers and deprecation policy;
- keep stable-major approval disabled.

### Phase 1: Structural and Compatibility Blockers

- close RHX-1.0-001 with exact matrix evidence;
- close RHX-1.0-002 with no Devise package knowledge in core;
- close RHX-1.0-005 with public registry, ABI, diagnostics, and migrations;
- close RHX-1.0-009 with canonical output containment and regression tests;
- retain all compiler, snapshot, runtime, browser, production, and package gates.

### Phase 2: Missing Stable Evidence

- close RHX-1.0-003 with measured baselines;
- close RHX-1.0-004 with exercised failure-to-source workflows;
- close RHX-1.0-006 with a pure-Ruby release consumer;
- close RHX-1.0-007 with Ruby advisory and disclosure operations;
- close RHX-1.0-008 with public ownership.

### Phase 3: RC and Upgrade Rehearsal

On one exact RC SHA:

- upgrade and roll back pure-Ruby and Rails fixtures from v0.4.0;
- pass compiler suite on every supported Ruby;
- pass Rails runtime on every supported Ruby/Rails pair;
- pass representative browser and production lanes;
- pass package, reproducibility, advisory, benchmark, and debugging lanes;
- ensure the claim matrix has no unsupported public wording;
- leave no open P0/P1 finding.

### Phase 4: RC Hardening

- cut another RC when Tier A/B/C or matrix behavior changes;
- review performance variance and flakes;
- rehearse install, update, and uninstall in clean environments;
- close or explicitly schedule P2 findings without broad claims;
- operationally check security and support channels.

### Phase 5: Independent Rerun and Approval

- rerun the complete review against the exact proposed release commit;
- require all fifteen dimensions to be proven or honestly narrowed with no P0/P1;
- require exact canonical CI and hosted RC evidence;
- record matrix dates, API inventory, upgrade, benchmark, debug, and ownership;
- change <code>approvedStableMajors</code> from empty to 1 only through a reviewed
  commit after the evidence review;
- publish 1.0.0 through the normal exact-SHA workflow.

## 13. Product-Owner Decisions

1. Is the first stable promise combined RubyHx/RailsHx, or may RubyHx become 1.0
   while RailsHx remains beta?
2. Which Ruby branches are worth ongoing operational support?
3. Should Node 22 remain the RC line with min/latest testing, or should the RC
   deliberately move to Node 24 LTS?
4. Which pure-Ruby product shape should be the reference: library plus CLI,
   service, or both?
5. Is the promised debugging unit Haxe/HHX source correlation or deterministic
   generated Ruby/ERB?
6. Does DeviseHx ship and version with core or independently?
7. What support model is sustainable and truthful?
8. Are verified GitHub Release assets acceptable as the long-term 1.0 channel?

## 14. Tracking

The review findings were recorded in the live bead database after the independent
pass:

| Finding | Bead |
| --- | --- |
| Stable blocker epic | haxe_ruby-1sd |
| RHX-1.0-001 support matrix | haxe_ruby-huf |
| RHX-1.0-002 companion extraction | haxe_ruby-8q9 |
| RHX-1.0-003 performance | haxe_ruby-0ss |
| RHX-1.0-004 debugging | haxe_ruby-9dm |
| RHX-1.0-005 public contract and upgrade | haxe_ruby-i1g |
| RHX-1.0-006 pure-Ruby project | haxe_ruby-1u1 |
| RHX-1.0-007 security operations | haxe_ruby-qrt |
| RHX-1.0-008 maintenance ownership | haxe_ruby-9xsp |
| RHX-1.0-009 generator output containment | haxe_ruby-08b2 |
| RHX-1.0-101 compiler decomposition | haxe_ruby-e2ba |
| RHX-1.0-102 shared behavior claim | haxe_ruby-r0h0 |

Do not close the stable-blocker epic merely because implementation changes
merge. Close each finding only with its named acceptance evidence, then rerun
the independent review against the exact RC.

## 15. External Primary Sources Used by the Review

- Exact reviewed CI:
  https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29289643234
- Releases:
  https://github.com/fullofcaffeine/reflaxe.ruby/releases
- Ruby 3.2 final status:
  https://www.ruby-lang.org/en/news/2026/03/27/ruby-3-2-11-released/
- Ruby branch status:
  https://www.ruby-lang.org/en/downloads/branches/
- Rails support windows:
  https://rubyonrails.org/2025/10/29/new-rails-releases-and-end-of-support-announcement
- Rails March 2026 security releases:
  https://rubyonrails.org/2026/3/23/Rails-Versions-7-2-3-1-8-0-4-1-and-8-1-2-1-have-been-released
- Haxe stable downloads:
  https://haxe.org/download/list/
- Node 22 patch context:
  https://nodejs.org/en/blog/release/v22.22.1

## 16. Owner Summary

The reviewed commit is a strong production-ready beta with broad exact-SHA CI,
real Rails runtime/browser/production evidence, fail-closed compiler tests, and
careful release integrity. It should not request 1.0.0 yet.

Eight P1 blockers remain: truthful version scope, core/DeviseHx separation,
performance baselines, debugging/source correlation, stable API and upgrade
policy, a realistic pure-Ruby Haxe-first workflow, Ruby advisory and disclosure
operations, and public maintenance ownership. Each has a bounded acceptance gate
or a narrower-scope alternative.

After those findings close, cut an RC, prove upgrade and rollback from v0.4.0,
rerun the complete matrix and this independent review, and only then approve
stable major 1.
