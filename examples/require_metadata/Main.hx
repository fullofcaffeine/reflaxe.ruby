// Require metadata smoke.
//
// Demonstrates: `@:rubyRequire` and `@:rubyRequireRelative` collection,
// de-duplication, and ordering for Ruby support files/gems.
// Type safety: extern classes give Haxe a typed boundary for Ruby constants even
// though the implementation lives in Ruby. Missing Haxe methods fail at compile
// time; missing Ruby files are caught when the generated Ruby is executed.
// IntelliSense: editors should complete `NativeJson.parse` and
// `NativeDate.today` from the extern declarations.
// Ruby output: generated `require` / `require_relative` lines in `run.rb`.

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
