package rails.active_job;

/**
	Typed extern for `ActiveJob::DeserializationError`.

	Use this with `discardOn(DeserializationError)` or `retryOn(...)` so the
	ActiveJob lifecycle DSL can read the `@:native` Ruby constant at compile
	time instead of requiring a repeated string literal.
**/
@:native("ActiveJob::DeserializationError")
extern class DeserializationError {}
