import ruby.Set;

class InvalidArrayAccess {
	static function main():Void {
		var values = new Set<String>(["typed"]);
		var raw:Array<String> = values;
		Sys.println(raw.length);
	}
}
