# RailsHx ActiveJob Guide

RailsHx jobs are Haxe-authored Rails jobs. The compiler emits ordinary
`ActiveJob::Base` subclasses; typed Haxe methods and metadata are the authoring
layer, not a parallel job runtime.

## Job Classes

Annotate a Haxe class with `@:railsJob` and extend `rails.active_job.Base`:

```haxe
@:railsJob
@:queueAs("mailers")
@:retryOn("StandardError", {waitSeconds: 5, attempts: 3})
@:discardOn("ActiveJob::DeserializationError")
class SendWelcomeEmailJob extends rails.active_job.Base {
	public function perform(userId:Int, email:String):Void {
		trace("welcome:" + email);
	}
}
```

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

## Runtime Strategy

`npm run test:active-job` is the fast compiler/static lane. It checks:

- `@:railsJob` emits an `ActiveJob::Base` subclass.
- queue/retry/discard metadata lowers to Rails class macros.
- `perform(...)` args lower to Ruby method args.
- generated `performLater`/`performNow` calls lower to Rails enqueue APIs.
- bad enqueue args fail during Haxe compilation.

Rails runtime execution should use the Rails test adapter in the generated app
lane. When Rails gems are installed, `REQUIRE_RAILS=1 npm run test:rails-runtime`
must make missing Rails runtime dependencies fail instead of silently skipping.
