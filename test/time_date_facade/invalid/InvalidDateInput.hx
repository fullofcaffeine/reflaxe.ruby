import ruby.Date as RubyDate;

class InvalidDateInput {
	static function main():Void {
		new RubyDate(2024, "February", 29);
	}
}
