package rails.active_support;

/**
	Typed entrypoint to Rails' extensions on Ruby's native `Time` constant.

	Rails applications configure a default `Time.zone`, so `current()` and
	`zone()` return the zoned contracts used by normal application code. Zone
	lookup remains available explicitly for deterministic services and tests.
	The facade maps directly to `Time.current`, `Time.zone`, and
	`Time.find_zone(!)` after loading ActiveSupport; it does not own global zone
	mutation or create a parallel time runtime.
**/
@:rubyRequire("active_support")
@:rubyRequire("active_support/time")
@:native("Time")
extern class RailsTime {
	/** Returns the current value in the Rails application zone. **/
	public static function current():TimeWithZone;

	/** Returns the Rails application's configured zone. **/
	public static function zone():TimeZone;

	/** Returns `null` when Rails cannot resolve `name`. **/
	@:native("find_zone")
	public static function findZone(name:String):Null<TimeZone>;

	/** Resolves `name` or lets Rails raise its normal ArgumentError. **/
	@:native("find_zone!")
	public static function findZoneRequired(name:String):TimeZone;
}
