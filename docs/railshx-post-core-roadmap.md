# RailsHx Post-Core Roadmap

Core RailsHx is the CRUD spine: models, queries, migrations, controllers,
templates, routes, generators, and Rails runtime tests. Post-core RailsHx should
grow outward only when the boundary is clear, typed, Rails-native, and testable.

This roadmap prevents ecosystem scope from blocking core RailsHx. Each surface
below should graduate only after it has a typed API boundary, compiler or macro
lowering strategy, generated Rails-shaped output, integration-test plan, and
documentation.

## Ordering

1. ActionMailer
2. ActiveJob
3. ActiveStorage
4. Hotwire/Turbo and ActionCable
5. ActiveSupport instrumentation and notifications
6. ViewComponent-style component contracts
7. Rails engines and plugin affordances

The order favors surfaces that reuse existing RailsHx assets first. Mailers can
reuse typed templates, route helpers, params-like locals, and Rails runtime
tests. Jobs can reuse typed service boundaries and generated Ruby constants.
Storage, realtime, instrumentation, and engines have wider runtime contracts and
should wait until the smaller post-core surfaces prove the pattern.

## Shared Graduation Criteria

A post-core surface is ready for implementation when all of these are true:

- The public Haxe API maps to a real Rails concept, not a Rails-inspired clone.
- Generated Ruby is recognizable Rails code and can be hand-reviewed by a Rails
  developer.
- Compile-time checks catch the mistakes Rails would otherwise discover late:
  missing templates, wrong locals, missing model fields, wrong attachment names,
  wrong job args, or wrong channel params.
- Runtime behavior can be proven by a generated Rails app lane or an explicit
  skip with `REQUIRE_RAILS=1` mandatory behavior.
- The first slice has a negative compile test and at least one generated Ruby
  shape assertion.
- Docs show Haxe source, generated Ruby, failure modes, and the Rails-owned
  source-of-truth policy.

## ActionMailer

Typed boundary:

- `rails.action_mailer.Base` for mailer classes.
- `Template<TLocals>` for HTML/text mailer templates.
- Typed `mail({to, from, subject, ...})` kwargs.
- Optional typed params facade for parameterized mailers.
- Initial slice exists through `@:railsMailer`,
  `rails.macros.MailerMacro.mailHtml/mailText/mailMultipart`, and typed HHX
  mail templates. See [RailsHx ActionMailer Guide](railshx-action-mailer-guide.md).

Lowering strategy:

- `@:railsMailer` emits `ActionMailer::Base` subclasses.
- Mailer actions stay normal Ruby instance methods.
- `MailerMacro` and HHX templates emit mailer-compatible ERB and Rails-native
  format render blocks.

Integration strategy:

- Generated Rails app runs an ActionMailer delivery test.
- Static smoke checks generated `mail(to:, subject:)` and template paths.
- Runtime lane checks multipart body rendering, mail headers, attachments, and
  `deliver_now` through the Rails test delivery collection when Rails gems are
  available.

Graduation criteria:

- Typed locals render both HTML and text templates.
- Missing template/locals failures happen at Haxe compile time.
- Generated mailer tests run under `REQUIRE_RAILS=1`.
- Parameterized mailers and previews are either implemented with typed APIs or
  explicitly deferred behind tracked beads.

## ActiveJob

Typed boundary:

- `rails.active_job.Base<TArgs>` or macro-generated `perform(...)` contracts.
- Queue name and retry/discard declarations as contextual lifecycle DSL calls
  with checked literals and typed exception refs.
- Typed enqueue helpers such as `MyJob.performLater(args)`.
- Initial slice exists through `@:railsJob`, contextual `lifecycle`
  queue/retry/discard declarations, legacy metadata compatibility, and
  macro-generated `performLater`/`performNow` helpers. See
  [RailsHx ActiveJob Guide](railshx-active-job-guide.md).

Lowering strategy:

- `@:railsJob` emits `ApplicationJob`/`ActiveJob::Base` subclasses.
- Haxe `perform` args lower to Ruby method args.
- Queue/retry/discard lifecycle declarations lower to Rails class macros.
- Static enqueue helpers lower to `perform_later` and `perform_now`.

Integration strategy:

- Static smoke checks `queue_as`, `retry_on`, `discard_on`, and `perform`.
- Runtime lane uses `ActiveJob::TestHelper` in a generated Rails app to assert
  queue name, enqueued args, serialized/deserialized typed arguments, performed
  jobs, and retry re-enqueue behavior.

Graduation criteria:

- Wrong job args fail in Haxe.
- Enqueue helpers preserve typed args.
- Generated Rails test proves job enqueue and perform flow under
  `REQUIRE_RAILS=1 npm run test:active-job`.
- Generated Rails test proves ActiveJob serialization/deserialization and at
  least one retry path through Rails' native `retry_on` machinery.

## ActiveStorage

Typed boundary:

- Attachment refs generated from model metadata: `User.attachments.avatar`.
- Typed single/many attachment declarations.
- Typed helpers for attach, attached, purge, and URL helper seams.
- Initial slice exists through `@:hasOneAttached`, `@:hasManyAttached`, and
  `Model.attachments.*` refs. See
  [RailsHx ActiveStorage Guide](railshx-active-storage-guide.md).

Lowering strategy:

- Extend `ModelMacro` metadata with `@:hasOneAttached` and
  `@:hasManyAttached`.
- Lower refs to Rails `has_one_attached` / `has_many_attached` and attachment
  receiver calls.

Integration strategy:

- Static smoke checks generated model declarations and typed refs.
- Runtime lane uses Rails test storage service and fixture upload.

Graduation criteria:

- Unknown attachment refs fail at compile time.
- Single vs many attachment helpers have distinct Haxe types.
- Runtime test proves attach/read/purge in generated Rails app.

## Hotwire, Turbo, And ActionCable

Typed boundary:

- Initial implemented slice: typed Haxe client helpers for Turbo events,
  `Turbo.visit` options/actions, frame attributes, and client-side
  `Turbo.renderStreamMessage`.
- Implemented slice: typed server-side Turbo stream helpers for
  `append`, `prepend`, `before`, `after`, `replace`, `update`, `remove`, and
  matching broadcast shapes. These use `StreamTarget`, `StreamName<TPayload>`,
  and `Template<TLocals>` while lowering to Rails `turbo_stream.*` and
  `Turbo::StreamsChannel.broadcast_*_to` calls.
- Initial implemented slice: `@:railsChannel` classes, typed
  `Channel<TParams, TPayload>`, typed subscription params, typed streams,
  `ActionCable.broadcast(...)`, and a Haxe JS facade for
  `consumer.subscriptions.create(...)`. See
  [RailsHx ActionCable Guide](railshx-action-cable-guide.md).
- Broaden typed Turbo stream helpers to additional Rails helper shapes such as
  refresh and model callback macros where the target Rails API shape is proven,
  plus runtime Rails test coverage.
- Haxe-authored JS clients that layer on Rails importmap/Turbo conventions.
- `rails.action_cable.Channel<TParams>` for channel params and stream names.

Lowering strategy:

- Keep Turbo output Rails-native: `turbo_stream.*` and Rails broadcast helpers.
- Compile Haxe JS to importmap-friendly assets under `app/javascript/railshx`.
- Channels emit normal `ActionCable::Channel::Base` subclasses.

Integration strategy:

- Playwright tests for Turbo UX.
- Rails channel tests use `ActionCable::Channel::TestCase` in a generated Rails
  app for subscribe/stream/perform/broadcast behavior.
- Static smoke checks generated JS importmap pins and channel Ruby.

Graduation criteria:

- Typed stream targets/actions avoid behavior-bearing string drift.
- Browser sentinel proves progressive enhancement remains Rails/Turbo-native.
- Channel params are typed and runtime-tested under
  `REQUIRE_RAILS=1 npm run test:action-cable`.

## ActiveSupport Instrumentation

Typed boundary:

- Initial implemented slice: `rails.active_support.EventName<TPayload>`,
  `Notifications.instrument(...)`, `Notifications.subscribe(...)`,
  `Notifications.monotonicSubscribe(...)`, and `NotificationEvent<TPayload>`.
  See [RailsHx ActiveSupport Instrumentation Guide](railshx-instrumentation-guide.md).
- Typed event-name abstracts for app-owned events.
- Typed payload typedefs for known app events.

Lowering strategy:

- Lower to `ActiveSupport::Notifications.instrument`.
- Lower subscriptions to `ActiveSupport::Notifications.subscribe` and
  `ActiveSupport::Notifications.monotonic_subscribe`.
- Keep event names as Rails strings, but expose typed constants/abstracts in
  Haxe.
- Lower typed payload field reads such as `event.payload.listId` to Rails-style
  `event.payload[:list_id]`.

Integration strategy:

- Runtime smoke subscribes to an event and verifies payload when ActiveSupport
  is locally available.
- Static smoke checks generated Ruby shape and no raw string drift in examples.
- Negative Haxe compile tests cover missing publish payload fields and wrong
  subscriber payload field types.

Graduation criteria:

- App-owned events have typed payload contracts.
- Subscribers and publishers share the same event constants.
- Runtime lane proves publish/subscribe.

## ViewComponent-Style Components

Typed boundary:

- Initial implemented slice: `rails.action_view.Component<TLocals>`,
  `Slot.content()`, and HHX `<component component=${...}>` capture/render
  composition. See [RailsHx Components Guide](railshx-components-guide.md).
- Component partials with typed locals and typed slots.
- HHX component invocation with checked locals/slots.
- Interop with existing Ruby ViewComponent classes through extern contracts.

Lowering strategy:

- Do not copy Phoenix components directly. Use the existing RailsHx typed slot
  lesson: typed HHX children are captured and passed to Rails-native render
  calls.
- Lower `Component<TLocals>` calls to `capture do ... end` plus normal
  `render partial:` locals.
- If ViewComponent is present, generate normal Ruby component classes or typed
  extern wrappers; otherwise stay in Rails partial/component helpers.

Integration strategy:

- Static smoke checks generated capture/render output plus slot/arg failures.
- Runtime Rails view test renders generated component output.

Graduation criteria:

- Slot names and required args fail at Haxe compile time.
- Existing Ruby components can be consumed without rewrite.
- Generated output is normal Rails/ViewComponent code.

## Rails Engines And Plugins

Typed boundary:

- Initial implemented slice: safe engine/plugin output roots through
  `reflaxe_ruby_rails_output_root`, generator `--rails-output-root`, generated
  autoload/eager-load initializer, and host-app extern consumption guidance.
  See [RailsHx Engines And Plugins Guide](railshx-engines-plugins-guide.md).
- Namespace-aware route/model/controller helper contracts for future slices.
- Generator options for mountable engine layout.
- Typed route sync that preserves engine namespace and mount paths.

Lowering strategy:

- Extend output-root and route generator configuration before adding new DSLs.
- Prefer Rails generator adapters and Ruby-native install tasks.
- Keep generated artifacts as normal Rails/Ruby constants under the configured
  output root.

Integration strategy:

- Focused engine/plugin smoke checks engine-local output, autoload config,
  generator build config, Ruby execution, and unsafe path failures.
- Generated dummy app or engine fixture for broader follow-up work.
- Route helper sync smoke for mounted routes.
- Optional Rails runtime lane with engine dummy app when dependencies exist.

Graduation criteria:

- Namespaced constants and file paths are deterministic.
- Engine route helpers are typed and do not collide with app helpers.
- Generated dummy app boots under `REQUIRE_RAILS=1`.

## Deferred Ideas

These should stay out of implementation until a concrete app need appears:

- Haxe-first Rails route emission. Route-helper sync remains phase 1.
- ORM-independent RailsHx abstractions. RailsHx should stay Rails-native.
- LLM-generated framework bindings without deterministic validation. LLMs can
  suggest typed externs, but file existence, source parsing, and compile tests
  must fail closed.
- A Ruby `metal` profile. Ruby-first plus portable remains the profile model.
