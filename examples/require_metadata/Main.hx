@:rubyRequire("set")
@:rubyRequire("json")
@:rubyRequire("json")
@:rubyRequireRelative("./support/native_time")
extern class NativeJson {
	public static function parse(value:String):Dynamic;
}

@:rubyRequire("date")
@:rubyRequireRelative("./support/native_date")
extern class NativeDate {
	public static function today():Dynamic;
}

class Main {
	static function main() {
		NativeJson.parse("{}");
		NativeDate.today();
		Sys.println("require metadata");
	}
}
