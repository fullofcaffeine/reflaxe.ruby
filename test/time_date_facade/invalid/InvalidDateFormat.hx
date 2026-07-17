import ruby.Date as RubyDate;

class InvalidDateFormat {
	static function main():Void {
		RubyDate.parseWithFormat("2024-02-29", 2024);
	}
}
