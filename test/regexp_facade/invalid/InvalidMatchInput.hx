import ruby.Regexp;

class InvalidMatchInput {
	static function main():Void {
		new Regexp("ruby").match(42);
	}
}
