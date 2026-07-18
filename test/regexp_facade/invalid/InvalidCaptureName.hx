import ruby.Regexp;

class InvalidCaptureName {
	static function main():Void {
		var match = new Regexp("(?<word>ruby)").match("ruby");
		if (match != null) {
			match.capture("word");
		}
	}
}
