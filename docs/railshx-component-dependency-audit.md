# RailsHx Component Dependency Closure

Stable RailsHx does not require every Haxe standard-library module or a typed
facade for every Ruby standard-library API. It does require the complete
dependency closure of every RailsHx component slice that the project describes
as supported.

For a supported slice, all required Haxe language and std behavior, compiler
lowering, `hxruby` runtime behavior, direct `ruby.*` facades, Rails/gem APIs,
generated artifacts, and representative target execution must be covered by
mandatory evidence. If one of those dependencies is missing, the owning slice
must be implemented, narrowed, or made to fail closed before release. A green
unrelated reference-app path is not substitute evidence.

The machine-readable source is
[`railshx-component-dependencies.json`](railshx-component-dependencies.json).
Validate it with:

```bash
npm run test:railshx-component-dependencies
```

## What The Guard Proves

The guard checks that:

- every component family has an exact public claim marker, bounded scope,
  source roots, target dependencies, and compile/negative/target evidence;
- every named evidence command exists and is mandatory in the full,
  Rails-runtime, browser, or production CI lane that owns it;
- the shared Haxe std foundations are classified as covered by the upstream
  parity ledger;
- the generated-code runtime files are implemented in the std/runtime
  inventory;
- direct `haxe.*` and `sys.*` imports in maintained RailsHx, DeviseHx, and
  component examples are accounted for by the Haxe std parity ledger;
- no supported source imports or directly references an
  `upstream-fallback-candidate`, `ruby-override-needed`, or
  `unsupported-target-specific` parity entry; and
- direct `ruby.*` imports resolve to implemented typed facades in the committed
  std inventory.

Implicit language behavior such as strings, arrays, nullable values, functions,
exceptions, reflection, and JSON is owned by the shared compiler/std/runtime
evidence listed in the machine audit. Component-specific target behavior is
owned by the component commands. This combination avoids pretending that a
textual import scan proves runtime semantics.

## Audited Component Families

| Component family | Supported slice | Required target evidence |
| --- | --- | --- |
| ActionCable | Channels, connections, server-derived typed client subscriptions, streams, payloads and perform actions | Generated Rails channel tests plus stock Haxe JS, Genes and browser-client sentinels |
| ActionController and routing | Controllers, lifecycle, params, request/response, route refs and Haxe-owned route DSL | Rails request/integration runtime |
| ActionMailer | Mailers, params, templates, attachments, previews and delivery | Generated Rails mailer tests |
| ActionView, HHX and components | Typed templates, helpers, forms, partials, layouts, capture and slots | Rails integration, Chromium and production dogfood |
| ActiveJob | Enqueue/perform, typed arguments, retry/discard and test adapter | Generated Rails job tests |
| ActiveRecord and migrations | Models, relations, documented query/projection slice and migrations | In-memory ActiveRecord result-adapter execution, SQLite migrations/integration and production dogfood |
| ActiveStorage | Attachments, attachables, signed IDs, direct upload helpers, reads and purge | Generated ActiveStorage Rails tests |
| ActiveSupport and instrumentation | Receiver facades, modern Rails zoned time through TimeZone/TimeWithZone, and typed Notifications events/subscriptions | Mandatory exact-Rails component runtime |
| DeviseHx | Typed model/scope/filter/params/routes/HHX/test/current-user contracts used by the reference app | Chromium and production reference app |
| Engines, autoload and concerns | Engine-local output, autoload integration, concern shape and host consumption | Ruby host execution plus mandatory exact-Rails concern runtime |
| Generators, adoption and tests | Public generators, Rails-owned adoption, ownership safety and test generation | Mandatory real Rails generator loading plus mixed-app Rails runtime |
| Reference application | Combined compile, Rails, database, browser, assets and production path | Rails runtime, Chromium and production lanes |
| Turbo and Hotwire | Typed client events/frames and server stream target/render/broadcast slice | Chromium and production reference app |

The ActiveSupport, concern, and real Rails generator checks share
`npm run test:rails-component-runtime`. That command installs the exact verified
Rails version in an isolated Bundler context and sets `REQUIRE_RAILS=1`, so
missing gems fail instead of turning those runtime checks into optional skips.

## Result And Limits

At the 2026-07-18 audit, the supported roots directly use only
Haxe/sys modules classified as covered. The direct Ruby facade imports are
`ruby.Date`, `ruby.File`, `ruby.StandardError`, and `ruby.Time`; all are
implemented and exercised by their owning ActiveSupport temporal,
ActiveStorage, and ActiveJob paths. No supported component imports
one of the unfinished Haxe parity candidates. This guard and the mandatory
Rails 8.1.3 runtime matrix on Ruby 3.3, 3.4, and 4.0 remain required by
exact-SHA canonical CI; hosted run identities are recorded in
[Live Release Protocol Evidence](release-live-evidence.md).

This result does not make a whole-Haxe-stdlib or whole-Ruby-stdlib claim. The
remaining parity candidates stay unavailable to the stable contract unless a
future supported component begins to require one. Adding such a dependency
will fail this guard until parity evidence is added. Likewise, each component
row covers only the documented slice, not every upstream Rails option, adapter,
or extension point.

## Maintenance Rule

When widening a public RailsHx component:

1. Update its scope and target dependencies in the machine audit.
2. Add compile and negative evidence for the new typed contract.
3. Add mandatory Rails, browser, or production evidence when behavior depends
   on the target runtime.
4. Add Haxe std parity or an implemented `ruby.*` facade before using a new
   dependency from supported source.
5. Keep unsupported upstream breadth outside the claim and fail closed when
   the compiler has enough information to diagnose it.
