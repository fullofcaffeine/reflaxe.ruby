import ruby.Time as RubyTime;

class InvalidTimeArithmetic {
	static function main():Void {
		RubyTime.utc(2024, 2, 29).addSeconds("one hour");
	}
}
