import ruby.Regexp;

class InvalidByteOffset {
	static function main():Void {
		var match = new Regexp("ruby").match("ruby");
		if (match != null) {
			match.byteOffset(0);
		}
	}
}
