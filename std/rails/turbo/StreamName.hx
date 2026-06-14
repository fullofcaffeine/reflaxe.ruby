package rails.turbo;

/**
	Typed stream name token for Rails Turbo broadcast helpers.

	`TPayload` carries the locals/payload shape associated with this stream. The
	value erases to Rails' ordinary stream name string, but no implicit
	`from String` conversion is provided so broadcast names stay centralized in
	typed constants or explicit `StreamName.named(...)` calls.
**/
abstract StreamName<TPayload>(String) to String {
	public inline function new(value:String) {
		this = value;
	}

	public static function named<TPayload>(name:String):StreamName<TPayload> {
		return new StreamName<TPayload>(name);
	}
}
