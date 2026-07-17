import ruby.Time as RubyTime;

class InvalidTimeInput {
	static function main():Void {
		RubyTime.utc("2024", 2, 29);
	}
}
