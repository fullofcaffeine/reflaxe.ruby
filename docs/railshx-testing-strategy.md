# RailsHx Testing Strategy

RailsHx is a compiler/code generator first. The most important test artifact is
therefore the generated Ruby/Rails output: it should be stable, idiomatic, and
reviewable as if a Rails developer had written it by hand.

## Testing Pyramid

1. Snapshot tests are the primary compiler/codegen contract.
2. Negative Haxe compile tests prove type-safety and fail-closed boundaries.
3. Smoke tests prove focused invariants such as file existence, Ruby syntax,
   generator/package shape, and explicit escape-hatch policy.
4. Rails runtime tests prove thin Rails consumption seams only.
5. Browser and production dogfood tests prove the end-to-end app workflow.

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
| Rails interop/adoption | Runtime/request smoke plus negative external-template checks, no committed mixed-app snapshot. | Needs a snapshot contract for generated Haxe-owned Ruby/ERB while keeping Rails-owned legacy files out of snapshots unless explicitly fixture-owned. | Add rails interop snapshots for generated controller/service/view/template output. |
| Rails engine/plugin | Smoke-heavy, no committed engine-local output snapshot. | Needs snapshot coverage because engine-local autoload and output-root shape are compiler output. | Add engine/plugin snapshots for engine-local generated files and initializer. |
| Generators and package/release checks | Smoke/check scripts only. | Appropriate. These are command/product-shape checks more than compiler-output snapshots. | Keep smoke/check style; add golden fixture snapshots only if generator output becomes complex or unstable. |
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

- Add snapshots for remaining smoke-heavy output surfaces: Rails interop and
  Rails engine/plugin output.
- After those snapshots exist, trim duplicated output-shape regex assertions in
  the corresponding smoke scripts. Keep syntax checks, negative compile tests,
  unsafe-path checks, generator checks, and Rails runtime seams.
- Keep package/release/generator checks as smoke/check scripts unless their
  generated output becomes complex enough to need golden fixtures.

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

## Haxe-Authored Test Layers

Vanilla Ruby/Rails tests remain first-class. Generated RailsHx output should be
ordinary idiomatic Ruby, so teams can use Minitest, RSpec, Rails request tests,
system tests, and normal JavaScript/browser tooling without RailsHx-specific
runtime requirements.

RailsHx should also grow optional typed Haxe-authored test layers where that
improves developer experience:

- Haxe-authored Ruby/Rails tests can reuse typed model fields, route helpers,
  params contracts, template refs, and generated constants before lowering to
  ordinary Ruby/Rails test files.
- Haxe-authored JS/browser tests can reuse shared Haxe DOM hooks, Turbo event
  contracts, route constants, and typed client payloads before lowering to
  Playwright/Vitest-compatible JavaScript or TypeScript.
- The typed test layers should be additive, not mandatory. If a user prefers
  vanilla Rails tests, those tests should keep working against generated RailsHx
  code as if it had been hand-written.

Use `../haxe.elixir.codex` as inspiration for the ergonomics, but adapt the
output to Rails and modern Ruby/JS testing conventions rather than copying
Phoenix-specific shapes.
