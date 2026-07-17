class InvalidTimeParsing {
	static function main():Void {
		var value = ruby.TimeParsing.parseIso8601(20260717);
		Sys.println(value);
	}
}
