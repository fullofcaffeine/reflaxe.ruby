// Pure RubyHx callable ABI tour.
//
// Demonstrates: Haxe-owned direct, captured, forwarded, optional, and
// keyword-plus-block methods and a Ruby stdlib extern whose callback becomes a
// native block.
// Type safety: callback arguments/results and keyword fields are completed and
// checked by Haxe; no Dynamic carrier or Ruby-syntax escape is involved.
// IntelliSense: editors expose each precise callback signature, the optional
// callback, `CallableOptions`, and the precise Ruby stdlib extern lifecycle.
// Ruby output: ordinary `yield`, `&block`, keyword arguments, and
// `Tempfile.create { ... }` with no HXRuby semantic helper calls.

/** Exact console overloads keep the example typed without a broad value seam. **/
@:native("Kernel")
extern class CallableConsole {
	@:native("puts")
	public static function putInt(value:Int):Void;

	@:native("puts")
	public static function putString(value:String):Void;
}

/** Minimal file capability yielded by the scoped Tempfile operation below. **/
@:native("File")
extern class ScopedFile {
	public function write(value:String):Int;
	public function rewind():Int;

	@:native("read")
	public function readAll():String;
}

/** Precise Ruby stdlib extern whose typed callback lowers to a native block. **/
@:rubyRequire("tempfile")
@:native("Tempfile")
extern class ScopedTempfile {
	@:native("create")
	@:rubyBlockArg
	public static function create(baseName:String, block:ScopedFile->String):String;
}

class Main {
	static function main():Void {
		CallableConsole.putInt(CallableApi.direct(3, value -> value * 2));

		var capturedCallback = CallableApi.capture(value -> value + 10);
		CallableConsole.putInt(capturedCallback(1));
		CallableConsole.putInt(CallableApi.forward(4, value -> value * 3));

		CallableConsole.putInt(CallableApi.optional(7));
		CallableConsole.putInt(CallableApi.optional(7, value -> value + 5));
		CallableConsole.putString(CallableApi.decorate("ruby", {prefix: "typed-", suffix: "!"}, value -> value.toUpperCase()));

		var tempfileResult = ScopedTempfile.create("rubyhx-callable-", function(file) {
			file.write("extern-block");
			file.rewind();
			return file.readAll();
		});
		CallableConsole.putString(tempfileResult);
	}
}
