# RailsHx Testing Strategy

RailsHx is a compiler/code generator first. The most important test artifact is
therefore the generated Ruby/Rails output: it should be stable, idiomatic, and
reviewable as if a Rails developer had written it by hand.

## Testing Pyramid

1. Snapshot tests are the primary compiler/codegen contract.
2. Negative Haxe compile tests prove type-safety and fail-closed boundaries.
3. Smoke tests prove focused invariants such as file existence, Ruby syntax,
   generator/package shape, and explicit escape-hatch policy.
4. Example compile gates prove public examples still type-check after compiler
   and std/framework changes.
5. Rails runtime tests prove thin Rails consumption seams only.
6. Browser and production dogfood tests prove the end-to-end app workflow.

Runtime tests should not retest Rails itself. They should prove that generated
files land where Rails expects them and can be consumed through normal Rails
load/render/migrate/deliver/subscribe/asset paths.

## Current Ratio Review

| Surface | Current coverage | Ratio assessment | Next action |
| --- | --- | --- | --- |
| Core Ruby output | Smoke plus snapshots for core subset, class members, lambdas, enums, switches, exceptions, stdlib MVP, native mapping, call shapes, interop, and extensions. | Healthy. Smokes mostly execute or sanity-check focused behavior while snapshots own output shape. | Keep as-is unless a smoke grows large enough to duplicate snapshots. |
| Rails ActiveRecord/model/controller/mail/job/storage/todoapp | Smoke plus committed snapshots and runtime seams where needed. | Mostly healthy. Some smokes still contain duplicated output-shape regexes, but snapshots now carry the canonical output contract. | Gradually trim duplicate shape assertions from snapshot-backed smokes, keeping negative compile and runtime seam checks. |
| ActionCable | Smoke/runtime plus committed snapshots added for generated channel output. | Healthy after the ActionCable snapshot addition. | Keep runtime tests seam-focused: connection stubs, reject, unsubscribe, perform, broadcast. |
| Components | Snapshot-backed plus focused smoke. | Healthy after component snapshots. | Keep smoke limited to file presence, Ruby syntax, and negative slot/locals/template checks. |
| Turbo Streams | Snapshot-backed plus focused smoke. | Healthy after Turbo Streams snapshots. | Keep smoke limited to file presence, Ruby syntax, and negative stream target/locals checks. |
| ActiveSupport instrumentation | Snapshot-backed plus focused smoke/runtime-if-available. | Healthy after instrumentation snapshots. | Keep smoke limited to file presence, Ruby syntax, negative event/payload typing, and optional ActiveSupport consumption. |
| Rails interop/adoption | Snapshot-backed for RailsHx-owned output plus focused interop smoke/runtime-if-available. | Healthy after mixed-app snapshots. | Keep smoke focused on external ERB not being overwritten, checked locals/path failures, materialization, syntax, and request tests. |
| Rails engine/plugin | Snapshot-backed plus focused smoke/generator checks. | Healthy after engine/plugin snapshots. | Keep smoke limited to syntax, executable output, unsafe output-root rejection, and generator CLI checks. |
| Rails routing | Snapshot-backed for the focused `examples/rails_routes_dsl` output plus todoapp runtime/request seams and negative route DSL smoke. | Healthy. Snapshots own generated `config/routes.rb` and `.railshx/routes.haxe.json`; smoke owns invalid DSL diagnostics, unsafe escapes, route-helper generation, parity seams, and the Haxe-authored route parity core dogfood freshness check. | Keep exact output changes in snapshots. Keep runtime tests thin: route recognition/helper existence/request dispatch where Rails must consume generated routes. |
| Examples | `npm run test:examples-compile` compiles every `examples/*/Main.hx` entrypoint plus known example client builds, and audits that each example declares snapshot/smoke/runtime/browser coverage. | New baseline. This catches stale examples and route/template/model drift before a user copies broken sample code. | Keep small compiler examples snapshot-backed; keep larger Rails examples on focused snapshots plus smoke/runtime/browser tests instead of snapshotting entire generated apps redundantly. |
| Generators and package/release checks | Smoke/check scripts, with golden snapshots for complex generated contracts such as DeviseHx app-local auth layers. | Healthy. CLI/product behavior stays in smoke; generated Haxe/docs/JSON output gets snapshots once users will review or depend on it. | Keep generic generator checks smoke-focused, but require snapshots plus Haxe compile checks for typed gem-layer contracts. |
| Browser/production dogfood | Playwright and production smoke. | Appropriate. These prove UX and deployable app seams, not compiler output. | Keep thin and user-visible. |

## Smoke Test Rules

- Keep smoke tests targeted. Prefer assertions such as "file exists", "Ruby
  syntax checks", "invalid Haxe source fails", "Rails can render this generated
  template", or "generator rejects unsafe paths".
- Avoid large regex suites that duplicate committed snapshots. If a regex exists
  only to prove exact generated Ruby shape, prefer a snapshot.
- Every smoke test needs a reason to exist. If the reason is not obvious from
  the script name, add a short script comment or cover it in this document.
- Keep runtime materialization small. Runtime lanes should boot enough Rails to
  consume generated artifacts, not cover Rails framework behavior broadly.
- Examples are executable QA assets. Every example entrypoint should stay in
  `test:examples-compile`, and that gate should list its expected-output/test
  contract. Compile-only coverage is enough only when compiler typing/snapshots
  fully own the contract; otherwise add focused smoke/runtime/browser coverage.
- When a smoke test discovers an important generated-output shape, add the shape
  to `scripts/ci/snapshot-harness.js` or file a bead explaining why that output
  cannot be snapshotted yet.

## Smoke Justification Checklist

Use this checklist when adding or reviewing a smoke test:

| Smoke assertion kind | Keep as smoke? | Why |
| --- | --- | --- |
| Exact generated Ruby/ERB/JS text shape | No, not by itself. | This is snapshot territory. Add a committed snapshot and remove or minimize the duplicate regex. |
| Required output file exists | Yes, if the file is not already listed in the snapshot harness. | Useful for generator/materializer commands and optional outputs; snapshot harness already checks listed files. |
| `ruby -c` syntax check | Yes. | Snapshots show text, but Ruby parser acceptance is a separate target-language sanity check. |
| Invalid Haxe fixture must fail | Yes. | Snapshots cover successful output; negative compile behavior needs explicit failure tests. |
| Strict boundary/policy scan | Yes. | These are repository policy checks, not generated-output contracts. |
| Runtime Rails boot/render/migrate/deliver/subscribe check | Yes, thinly. | Snapshots cannot prove Rails consumes paths, constants, templates, migrations, or framework test harnesses. |
| Package/generator command behavior | Yes. | These validate CLI/product workflow and unsafe input rejection, not only compiler output. |
| Full framework behavior already owned by Rails | Usually no. | Trust Rails unless RailsHx added custom runtime logic or generated an integration seam Rails must interpret. |

## Immediate Follow-Ups

- Keep package/release/generator checks as smoke/check scripts unless their
  generated output becomes complex enough to need golden fixtures.
- Typed RailsHx gem layers, including DeviseHx, use a stricter variant of that
  rule: smoke tests cover deterministic inventory and fail-closed adoption,
  snapshots cover generated contracts/docs/JSON, Haxe compile checks prove the
  contracts are usable, and later dogfood apps cover only Rails consumption
  seams such as login/logout flows. Do not re-test the wrapped Ruby gem's own
  behavior unless RailsHx adds runtime logic.
- When a smoke grows new generated-output text assertions, first ask whether the
  output belongs in `scripts/ci/snapshot-harness.js` instead.
- `test:route-parity-dogfood` is a generated-source freshness check, not a broad
  runtime test: it recompiles `tools/route_parity_hx` and byte-compares the
  committed generated Ruby parity core snapshot files under
  `lib/hxruby/generated/route_parity`. That Haxe-authored core is the first
  serious Ruby tooling dogfood slice: it uses typed `ruby.Json`/`ruby.File`
  externs to emit direct `JSON.parse`/`File.read` Ruby while a Ruby-native
  adapter keeps Rails/Rake UX. The surrounding `test:routes-generator` smoke
  owns the route helper/parity behavior and diagnostics.

## Todoapp Dogfood Coverage

`examples/todoapp_rails` is the canonical RailsHx dogfood app and should be
tested like a small production Rails app, not just like a compiler fixture:

- Generated Rails model/unit tests cover model behavior exposed by Haxe-authored
  ActiveRecord models and scopes.
- Generated controller/request tests cover route wiring, strong params,
  rendering, redirects, and generated ActionView consumption.
- Rails integration/runtime gates cover migrations, Zeitwerk/autoload,
  template materialization, app-local Bundler/Rails execution, and assets.
- Production smoke covers deployable boot, asset precompile, and release archive
  shape.
- Playwright covers user-visible browser behavior: ActionView output, Turbo,
  importmap, Haxe-authored JavaScript, form submission, and UX regressions.

When the todoapp grows to illustrate a new RailsHx compiler or framework
feature, add the corresponding Rails-style test layer in the same change. The
todoapp is allowed to be a broad dogfood sentinel; focused compiler details
still belong in snapshots, negative compile tests, and narrow smoke scripts.
Current generated Rails tests cover model validations, scopes, associations,
controller/request rendering, ordered open-work filtering, typed strong params,
invalid submissions, and redirects. Keep extending those ordinary Rails tests
when the todoapp demonstrates new ActiveRecord, controller, params, migration,
template, or route behavior.

## Haxe-Authored Test Layers

Vanilla Ruby/Rails tests remain first-class. Generated RailsHx output should be
ordinary idiomatic Ruby, so teams can use Minitest, RSpec, Rails request tests,
system tests, and normal JavaScript/browser tooling without RailsHx-specific
runtime requirements.

RailsHx should also provide typed Haxe-authored test layers as a first-class
authoring path where they improve developer experience. Generated RailsHx apps
and scaffolds should default to Haxe-authored tests, while raw Ruby/Rails and
TypeScript/JavaScript tests remain supported per test:

- Haxe-authored Ruby/Rails tests can reuse typed model fields, route helpers,
  params contracts, template refs, and generated constants before lowering to
  ordinary Ruby/Rails test files.
- The canonical Rails test authoring shape is a compiler-erased
  `@:railsTests static function define():Void` declaration host with top-level
  `test("...", () -> { ... })` calls. `@:test` methods remain a compatibility
  form, but helper methods must not be emitted as tests unless explicitly
  annotated.
- Haxe-authored JS/browser tests can reuse shared Haxe DOM hooks, Turbo event
  contracts, route constants, and typed client payloads before lowering to
  Playwright/Vitest-compatible JavaScript or TypeScript.
- The current todoapp browser slice uses
  `examples/todoapp_rails/e2e_haxe/TodoappBrowserSpec.hx` plus
  `examples/todoapp_rails/build-e2e.hxml` to emit Genes ES modules under
  `examples/todoapp_rails/e2e/generated/**`. The full Playwright sentinel
  compiles those Haxe specs before booting Rails, while
  `npm run test:haxe-playwright` keeps the generated JavaScript shape pinned
  without launching a browser.
- The typed test layers should be additive, not exclusive. If a user prefers a
  vanilla Rails or TypeScript test for a specific case, that test should keep
  working against generated RailsHx code as if it had been hand-written.

Use `../haxe.elixir.codex` as inspiration for the ergonomics, but adapt the
output to Rails and modern Ruby/JS testing conventions rather than copying
Phoenix-specific shapes.

See [RailsHx Haxe-Authored Testing Design](railshx-haxe-authored-testing-design.md)
for the proposed Minitest/RSpec and Playwright/Vitest output contracts.
