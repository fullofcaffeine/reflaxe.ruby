/** Proves the core `ruby.Time` facade does not introduce a library require. **/
class TimeOnly {
	static function main():Void {
		Sys.println(ruby.Time.utc(2024, 2, 29).strftime("%G-W%V-%u"));
	}
}
