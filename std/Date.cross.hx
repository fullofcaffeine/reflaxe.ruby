package;

class Date {
	public var year(default, null):Int;
	public var month(default, null):Int;
	public var day(default, null):Int;
	public var hours(default, null):Int;
	public var minutes(default, null):Int;
	public var seconds(default, null):Int;

	public function new(year:Int, month:Int, day:Int, hours:Int, minutes:Int, seconds:Int) {
		this.year = year;
		this.month = month;
		this.day = day;
		this.hours = hours;
		this.minutes = minutes;
		this.seconds = seconds;
	}

	public static function now():Date {
		return new Date(1970, 0, 1, 0, 0, 0);
	}

	public static function fromTime(time:Float):Date {
		return now();
	}

	public function getTime():Float {
		return 0.0;
	}

	public function toString():String {
		return year + "-" + (month + 1) + "-" + day + " " + hours + ":" + minutes + ":" + seconds;
	}
}
