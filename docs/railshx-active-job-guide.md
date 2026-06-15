# RailsHx ActiveJob Guide

RailsHx jobs are Haxe-authored Rails jobs. The compiler emits ordinary
`ActiveJob::Base` subclasses; typed Haxe methods and contextual lifecycle
declarations are the authoring layer, not a parallel job runtime.

## Job Classes

Annotate a Haxe class with `@:railsJob` and extend `rails.active_job.Base`:

```haxe
import rails.active_job.DeserializationError;
import rails.macros.JobDsl.*;
import ruby.StandardError;

@:railsJob
class SendWelcomeEmailJob extends rails.active_job.Base {
	static final lifecycle = {
		queueAs("mailers");
		retryOn(StandardError, {waitSeconds: 5, attempts: 3});
		discardOn(DeserializationError);
	}

	public function perform(userId:Int, email:String):Void {
		trace("welcome:" + email);
	}
}
```

`lifecycle` is a contextual RailsHx block. The calls are valid Haxe expressions,
validated by `rails.macros.JobDsl`, and erased by the Ruby compiler into Rails
class macros. Prefer typed exception refs such as `StandardError` and
`DeserializationError`; use `retryOnNamed("Ruby::Constant")` or
`discardOnNamed("Ruby::Constant")` only for external exceptions that do not have
a typed extern yet. Legacy `@:queueAs`, `@:retryOn`, and `@:discardOn` metadata
still compiles for compatibility, but new RailsHx jobs should use `lifecycle`.

Generated Ruby stays Rails-shaped:

```ruby
class SendWelcomeEmailJob < ActiveJob::Base
  queue_as :mailers
  retry_on StandardError, wait: 5.seconds, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(user_id, email)
    # normal generated Ruby body
  end
end
```

## Typed Enqueue Helpers

`rails.macros.JobMacro` derives static enqueue helpers from the `perform`
signature:

```haxe
SendWelcomeEmailJob.performLater(42, "reader@example.test");
SendWelcomeEmailJob.performNow(7, "now@example.test");
```

Those calls type-check in Haxe and lower to Rails:

```ruby
Jobs::SendWelcomeEmailJob.perform_later(42, "reader@example.test")
Jobs::SendWelcomeEmailJob.perform_now(7, "now@example.test")
```

If `perform` expects `(userId:Int, email:String)`, then
`performLater("not-an-int", 42)` fails during Haxe compilation.
`performNow(...)` preserves the declared return type of `perform(...)`, so a
job whose `perform` returns `String` can be assigned to `String` and will fail
if assigned to `Int`. `performLater(...)` returns a typed
`rails.active_job.Base` enqueue handle instead of `Dynamic`.

The generated Rails runtime lane also checks ActiveJob serialization for typed
perform arguments. A generated job instance serializes `(42,
"reader@example.test")` into Rails' normal `"arguments"` payload and
`ActiveJob::Base.deserialize(...)` restores the same generated job class and
typed argument values.

## Retry And Discard Runtime Coverage

Lifecycle declarations lower to Rails' own retry/discard class macros. The
canonical runtime fixture includes a `RetryProbeJob` that raises a generated
`HxException` from typed Haxe code:

```haxe
@:railsJob
class RetryProbeJob extends rails.active_job.Base {
	static final lifecycle = {
		queueAs("critical");
		retryOn(StandardError, {waitSeconds: 5, attempts: 2, queue: "retries"});
	}

	public function perform(attempt:Int):Void {
		throw "retry:" + Std.string(attempt);
	}
}
```

Because `HxException` is a Ruby `StandardError`, Rails' `retry_on
StandardError` handles it normally. The generated Rails test performs the job
through `ActiveJob::TestHelper` and asserts that the failed work is re-enqueued
on the typed retry queue.

## Runtime Strategy

`npm run test:active-job` is the fast compiler/static lane. It checks:

- `@:railsJob` emits an `ActiveJob::Base` subclass.
- `lifecycle` queue/retry/discard declarations lower to Rails class macros.
- `perform(...)` args lower to Ruby method args.
- generated `performLater`/`performNow` calls lower to Rails enqueue APIs.
- bad enqueue args fail during Haxe compilation.
- `performNow(...)` preserves the `perform(...)` return type and rejects wrong
  assignments during Haxe compilation.
- unsafe named exception constants fail during Haxe compilation.
- generated Rails serialization/deserialization preserves the generated job
  class and typed perform arguments.
- generated Rails retry behavior re-enqueues a failed typed Haxe job on the
  configured retry queue.
- when Rails gems are available, a generated Rails app uses
  `ActiveJob::TestHelper` to assert queue name, enqueue behavior,
  serialization/deserialization, retry behavior, and `perform_enqueued_jobs`
  execution.

Local `npm run test:active-job` skips the runtime Rails pass if the generated
app bundle is unavailable. `npm run test:rails-runtime` includes
`REQUIRE_RAILS=1 npm run test:active-job`, installs the generated app bundle
when needed, and makes missing Rails runtime dependencies fail instead of
silently skipping.

## Production Support Notes

The supported production path is Rails-native ActiveJob output plus typed Haxe
authoring. RailsHx does not wrap adapters; generated jobs use whichever
`config.active_job.queue_adapter` the Rails app configures.

Current runtime coverage uses Rails' test adapter because it is deterministic
and available in a generated app. Adapter-specific behavior for Sidekiq,
Solid Queue, Delayed Job, GoodJob, or custom adapters is intentionally deferred
to app/runtime integration tests unless a future RailsHx API needs adapter-aware
typing.

Queue names are checked non-empty literals in `queueAs(...)` and retry `queue`
options, then lowered to Rails symbols. If an app wants centralized queue names,
prefer a shared Haxe constant or typed wrapper consumed by `queueAs(...)`; a
future RailsHx queue-token API should preserve the same literal validation and
generated Rails `queue_as :name` output.

`discardOn(...)` is compiler-lowered and statically checked today. Runtime
coverage currently proves retry behavior; richer discard assertions and
adapter-specific failure diagnostics remain follow-up production-hardening work.
