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
- when Rails gems are available, a generated Rails app uses
  `ActiveJob::TestHelper` to assert queue name, enqueue behavior, and
  `perform_enqueued_jobs` execution.

Local `npm run test:active-job` skips the runtime Rails pass if the generated
app bundle is unavailable. `npm run test:rails-runtime` includes
`REQUIRE_RAILS=1 npm run test:active-job`, installs the generated app bundle
when needed, and makes missing Rails runtime dependencies fail instead of
silently skipping.
