package rails.active_support;

import ruby.Date;

/**
	Bounded native facade for `ActiveSupport::TimeZone`.

	Rails owns zone lookup and creates `TimeWithZone` values through this type;
	callers should not construct `TimeWithZone` themselves. Strict ISO 8601 and
	RFC 3339 entrypoints are exposed alongside concrete local/epoch creation.
	Permissive `parse`, open argument lists, mutable global configuration,
	ambiguous-local-time controls, and raw TZInfo objects are deliberately
	omitted so uncertainty does not leak into app-facing Haxe code.
**/
@:rubyRequire("active_support")
@:rubyRequire("active_support/time")
@:native("ActiveSupport::TimeZone")
extern class TimeZone {
	public function name():String;

	@:native("standard_name")
	public function standardName():String;

	@:native("utc_offset")
	public function baseUtcOffsetSeconds():Int;

	/** Formats the base offset; a concrete TimeWithZone reflects DST changes. **/
	@:native("formatted_offset")
	public function formattedOffset(?colon:Bool):String;

	/** Creates a wall-clock value in this zone using one-based months. **/
	public function local(year:Int, ?month:Int, ?day:Int, ?hour:Int, ?minute:Int, ?second:Float):TimeWithZone;

	/** Converts Unix epoch seconds into this zone. **/
	public function at(seconds:Float):TimeWithZone;

	/** Strictly parses an ISO 8601 value; missing time fields default to zero. **/
	@:native("iso8601")
	public function parseIso8601(value:String):TimeWithZone;

	/** Strictly requires the RFC 3339 time and offset components. **/
	@:native("rfc3339")
	public function parseRfc3339(value:String):TimeWithZone;

	public function now():TimeWithZone;

	public function today():Date;
}
