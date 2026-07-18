import ruby.Regexp;

class InvalidGlobalMatch {
	static function main():Void {
		Regexp.lastMatch();
	}
}
