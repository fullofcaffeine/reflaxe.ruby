class InvalidMain {
	static function main():Void {
		// The library boundary accepts text, so this must fail before Ruby output.
		TextAnalyzer.analyze("invalid.txt", 42);
	}
}
