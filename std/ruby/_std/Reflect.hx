package;

// Compiler-erased std facade: RubyCompiler lowers these calls directly to the
// compact HXRuby reflection helpers, so generated apps do not need a Reflect
// shell class that only delegates back into the runtime.
@:rubyNoEmit
class Reflect {
	public static function hasField(o:Dynamic, field:String):Bool {
		return cast untyped __ruby__("HXRuby.reflect_has_field({0}, {1})", o, field);
	}

	public static function field(o:Dynamic, field:String):Dynamic {
		return untyped __ruby__("HXRuby.reflect_field({0}, {1})", o, field);
	}

	public static function setField(o:Dynamic, field:String, value:Dynamic):Void {
		untyped __ruby__("HXRuby.reflect_set_field({0}, {1}, {2})", o, field, value);
	}

	public static function getProperty(o:Dynamic, field:String):Dynamic {
		return untyped __ruby__("HXRuby.reflect_get_property({0}, {1})", o, field);
	}

	public static function setProperty(o:Dynamic, field:String, value:Dynamic):Void {
		untyped __ruby__("HXRuby.reflect_set_property({0}, {1}, {2})", o, field, value);
	}

	public static function callMethod(o:Dynamic, func:haxe.Constraints.Function, args:Array<Dynamic>):Dynamic {
		return untyped __ruby__("HXRuby.reflect_call_method({0}, {1}, {2})", o, func, args);
	}

	public static function fields(o:Dynamic):Array<String> {
		return cast untyped __ruby__("HXRuby.reflect_fields({0})", o);
	}

	public static function isFunction(f:Dynamic):Bool {
		return cast untyped __ruby__("HXRuby.reflect_is_function({0})", f);
	}

	public static function compare<T>(a:T, b:T):Int {
		return cast untyped __ruby__("HXRuby.reflect_compare({0}, {1})", a, b);
	}

	public static function compareMethods(f1:Dynamic, f2:Dynamic):Bool {
		return cast untyped __ruby__("HXRuby.reflect_compare_methods({0}, {1})", f1, f2);
	}

	public static function isObject(v:Dynamic):Bool {
		return cast untyped __ruby__("HXRuby.reflect_is_object({0})", v);
	}

	public static function isEnumValue(v:Dynamic):Bool {
		return cast untyped __ruby__("HXRuby.reflect_is_enum_value({0})", v);
	}

	public static function deleteField(o:Dynamic, field:String):Bool {
		return cast untyped __ruby__("HXRuby.reflect_delete_field({0}, {1})", o, field);
	}

	public static function copy<T>(o:Null<T>):Null<T> {
		return cast untyped __ruby__("HXRuby.reflect_copy({0})", o);
	}

	@:overload(function(f:Array<Dynamic>->Void):Dynamic {})
	public static function makeVarArgs(f:Array<Dynamic>->Dynamic):Dynamic {
		return untyped __ruby__("HXRuby.reflect_make_var_args({0})", f);
	}
}
