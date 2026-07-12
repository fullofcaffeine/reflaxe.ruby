/**
	Executable contract for Haxe `Rest<T>` at a Ruby-owned method boundary.

	Haxe callers use the portable `...values` declaration/call syntax. The Ruby
	compiler must turn that one typed surface into normal `*values` parameters
	and `*array` calls, including constructors and forwarding.
**/
class RestShapes {
	public final values:Array<Int>;

	public function new(...values:Int) {
		this.values = values.toArray();
	}

	public static function join(prefix:String, ...values:Int):String {
		return prefix + ":" + values.toArray().join(",");
	}

	public function joinInstance(prefix:String, ...values:Int):String {
		return prefix + ":" + values.toArray().join(",");
	}

	public static function forward(prefix:String, ...values:Int):String {
		return join(prefix, ...values);
	}
}
