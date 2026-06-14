package rails.action_cable;

/**
	Typed ActionCable stream name token.

	`TPayload` carries the broadcast payload contract for the stream. The token
	erases to Rails' normal stream string through `to String`, but there is no
	implicit `from String`: app code must cross the boundary through
	`Stream.named(...)` or shared helpers so channel names remain searchable and
	payload-typed.
**/
abstract Stream<TPayload>(String) to String {
	public inline function new(value:String) {
		this = value;
	}

	public static function named<TPayload>(name:String):Stream<TPayload> {
		return new Stream<TPayload>(name);
	}
}
