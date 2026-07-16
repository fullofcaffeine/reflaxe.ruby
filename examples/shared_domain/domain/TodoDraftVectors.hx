package domain;

/** One input vector executed unchanged by generated Ruby and JavaScript. */
typedef TodoDraftVector = {
	var name:String;
	var title:String;
	var priority:Int;
}

/**
	Common runtime vectors for the shared todo-draft behavior.

	Keeping the inputs and renderer here means target-specific entrypoints cannot
	quietly choose different cases or normalize their results before comparison.
**/
class TodoDraftVectors {
	public static function render():String {
		var lines = [];
		for (vector in all()) {
			var result = TodoDraftContract.evaluate(vector.title, vector.priority);
			lines.push('{"case":${haxe.Json.stringify(vector.name)},"result":${TodoDraftContract.encode(result)}}');
		}
		return lines.join("\n") + "\n";
	}

	static function all():Array<TodoDraftVector> {
		return [
			{name: "normalizes whitespace", title: "  Ship\tRailsHx \n safely  ", priority: 2},
			{name: "preserves unicode", title: "  Café 👽  ", priority: 3},
			{name: "escapes serialized title", title: "Say \"hi\" \\ now", priority: 1},
			{name: "requires title", title: " \t\r\n ", priority: 1},
			{name: "limits utf16 title units", title: repeat("👽", 41), priority: 2},
			{name: "bounds priority", title: "Ship it", priority: 4},
			{name: "orders multiple errors", title: "  ", priority: 0},
		];
	}

	static function repeat(value:String, count:Int):String {
		var output = new StringBuf();
		for (_ in 0...count) {
			output.add(value);
		}
		return output.toString();
	}
}
