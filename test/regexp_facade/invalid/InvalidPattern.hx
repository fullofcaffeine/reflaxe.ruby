import ruby.Regexp;

class InvalidPattern {
	static function main():Void {
		new Regexp(42);
	}
}
