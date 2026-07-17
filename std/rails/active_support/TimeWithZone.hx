package rails.active_support;

import ruby.Time;

/**
	Read-only typed view of Rails' `ActiveSupport::TimeWithZone` value.

	Instances come from `RailsTime` or `TimeZone`, matching Rails' instruction
	not to invoke `TimeWithZone.new` directly. The bounded surface covers common
	calendar/zone reads, deterministic formatting, conversion to native Ruby
	`Time`, and seconds arithmetic. ActiveSupport duration/calendar arithmetic,
	broad delegation, mutable conversion, and DateTime/Rational contracts remain
	outside the facade.
**/
@:rubyRequire("active_support")
@:rubyRequire("active_support/time")
@:native("ActiveSupport::TimeWithZone")
extern class TimeWithZone {
	public function year():Int;

	public function month():Int;

	public function day():Int;

	public function hour():Int;

	@:native("min")
	public function minute():Int;

	@:native("sec")
	public function second():Int;

	public function zone():String;

	@:native("time_zone")
	public function timeZone():TimeZone;

	@:native("dst?")
	public function isDaylightSavingTime():Bool;

	@:native("utc?")
	public function isUtc():Bool;

	@:native("utc_offset")
	public function utcOffsetSeconds():Int;

	@:native("formatted_offset")
	public function formattedOffset(?colon:Bool):String;

	/** Returns the same instant as a UTC native Ruby Time. **/
	@:native("utc")
	public function toUtc():Time;

	/** Returns the same instant as a native Ruby Time with this fixed offset. **/
	@:native("to_time")
	public function toTime():Time;

	/** Formats this value as ISO 8601 with optional fractional-second digits. **/
	@:native("iso8601")
	public function toIso8601(?fractionDigits:Int):String;

	public function strftime(format:String):String;

	@:native("to_s")
	public function toString():String;

	/** Returns a new zoned value `seconds` after this instant. **/
	@:native("+")
	public function addSeconds(seconds:Float):TimeWithZone;

	/** Returns a new zoned value `seconds` before this instant. **/
	@:native("-")
	public function subtractSeconds(seconds:Float):TimeWithZone;

	/** Returns this instant minus `other`, measured in seconds. **/
	@:native("-")
	public function secondsSince(other:TimeWithZone):Float;
}
