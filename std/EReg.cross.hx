package;

class EReg {
	final pattern:String;
	final options:String;

	public function new(pattern:String, options:String) {
		this.pattern = pattern;
		this.options = options;
	}

	public function match(s:String):Bool {
		return false;
	}

	public function matched(n:Int):String {
		return "";
	}

	public function matchedLeft():String {
		return "";
	}

	public function matchedRight():String {
		return "";
	}

	public function matchedPos():{pos:Int, len:Int} {
		return {pos: 0, len: 0};
	}

	public function split(s:String):Array<String> {
		return [s];
	}

	public function replace(s:String, by:String):String {
		return s;
	}

	public function map(s:String, f:EReg->String):String {
		return s;
	}
}
