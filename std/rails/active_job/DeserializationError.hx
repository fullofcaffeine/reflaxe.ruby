package rails.active_job;

/**
	Typed extern for `ActiveJob::DeserializationError`.

	Use this with `discardOn(DeserializationError)` or `retryOn(...)` so the
	ActiveJob lifecycle DSL can read the `@:native` Ruby constant at compile
	time instead of requiring a repeated string literal.
**/
@:native("ActiveJob::DeserializationError")
extern class DeserializationError {
	/**
		Raises Rails' own `ActiveJob::DeserializationError`.

		This is a tiny typed facade for runtime discard tests and app code that
		needs to deliberately trigger Rails' discard path. The Ruby compiler
		lowers this method directly to `raise ActiveJob::DeserializationError...`
		so examples do not need raw `__ruby__` to exercise a Rails exception.
	**/
	public static function raise(?message:String):Void;
}
