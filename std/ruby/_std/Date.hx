package;

/**
	Ruby-backed Haxe `Date`.

	Haxe `Date` constructors/components are local-time oriented, while UTC
	accessors read the same instant through Ruby `Time#getutc`. `fromString()`
	uses a compact generated Ruby parser because Ruby's broader date parsing
	accepts input that Haxe does not promise.
**/
class Date {
	public function new(year:Int, month:Int, day:Int, hours:Int, minutes:Int, seconds:Int) {
		untyped __ruby__("@native_time = Time.local({0}, {1} + 1, {2}, {3}, {4}, {5})", year, month, day, hours, minutes, seconds);
	}

	public static function now():Date {
		return fromRubyTime(untyped __ruby__("Time.now"));
	}

	public static function fromTime(time:Float):Date {
		return fromRubyTime(untyped __ruby__("Time.at({0} / 1000.0).getlocal", time));
	}

	public static function fromString(value:String):Date {
		return
			fromRubyTime(untyped __ruby__("(begin string = {0}.to_s; if (match = /\\A(\\d{4})-(\\d{2})-(\\d{2})[ T](\\d{2}):(\\d{2}):(\\d{2})\\z/.match(string)); Time.local(match[1].to_i, match[2].to_i, match[3].to_i, match[4].to_i, match[5].to_i, match[6].to_i); elsif (match = /\\A(\\d{4})-(\\d{2})-(\\d{2})\\z/.match(string)); Time.local(match[1].to_i, match[2].to_i, match[3].to_i, 0, 0, 0); elsif (match = /\\A(\\d{2}):(\\d{2}):(\\d{2})\\z/.match(string)); Time.at((match[1].to_i * 3600) + (match[2].to_i * 60) + match[3].to_i).getlocal; else raise ArgumentError, 'Invalid date format'; end end)",
			value));
	}

	public function getTime():Float {
		return untyped __ruby__("@native_time.to_f * 1000.0");
	}

	public function getFullYear():Int {
		return untyped __ruby__("@native_time.year");
	}

	public function getMonth():Int {
		return untyped __ruby__("@native_time.month - 1");
	}

	public function getDate():Int {
		return untyped __ruby__("@native_time.day");
	}

	public function getDay():Int {
		return untyped __ruby__("@native_time.wday");
	}

	public function getHours():Int {
		return untyped __ruby__("@native_time.hour");
	}

	public function getMinutes():Int {
		return untyped __ruby__("@native_time.min");
	}

	public function getSeconds():Int {
		return untyped __ruby__("@native_time.sec");
	}

	public function getUTCFullYear():Int {
		return untyped __ruby__("@native_time.getutc.year");
	}

	public function getUTCMonth():Int {
		return untyped __ruby__("@native_time.getutc.month - 1");
	}

	public function getUTCDate():Int {
		return untyped __ruby__("@native_time.getutc.day");
	}

	public function getUTCDay():Int {
		return untyped __ruby__("@native_time.getutc.wday");
	}

	public function getUTCHours():Int {
		return untyped __ruby__("@native_time.getutc.hour");
	}

	public function getUTCMinutes():Int {
		return untyped __ruby__("@native_time.getutc.min");
	}

	public function getUTCSeconds():Int {
		return untyped __ruby__("@native_time.getutc.sec");
	}

	public function getTimezoneOffset():Int {
		return untyped __ruby__("(-@native_time.utc_offset / 60).to_i");
	}

	public function toString():String {
		return untyped __ruby__("@native_time.strftime('%Y-%m-%d %H:%M:%S')");
	}

	static function fromRubyTime(value:Dynamic):Date {
		var date = new Date(1970, 0, 1, 0, 0, 0);
		untyped __ruby__("{0}.instance_variable_set(:@native_time, {1})", date, value);
		return date;
	}
}
