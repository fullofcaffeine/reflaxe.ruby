/**
	Pure domain library shared by the generated CLI and handwritten Ruby callers.

	The implementation uses only typed Haxe strings and integers. Ruby output is
	a normal `TextAnalyzer.analyze(path, source)` class method returning a hash.
**/
class TextAnalyzer {
	public static function analyze(path:String, source:String):TextReport {
		return {
			path: path,
			lines: countLines(source),
			words: countWords(source),
			characters: source.length
		};
	}

	static function countLines(source:String):Int {
		if (source.length == 0) {
			return 0;
		}

		var lines = 1;
		for (index in 0...source.length) {
			if (source.charAt(index) == "\n") {
				lines += 1;
			}
		}
		return source.charAt(source.length - 1) == "\n" ? lines - 1 : lines;
	}

	static function countWords(source:String):Int {
		var words = 0;
		var insideWord = false;
		for (index in 0...source.length) {
			var character = source.charAt(index);
			var whitespace = character == " " || character == "\t" || character == "\n" || character == "\r";
			if (!whitespace && !insideWord) {
				words += 1;
			}
			insideWord = !whitespace;
		}
		return words;
	}
}
