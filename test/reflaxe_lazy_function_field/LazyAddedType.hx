/**
	Loaded only through `Context.getType` by the compiler probe so Haxe exposes
	its method type lazily, matching the upstream Reflaxe regression.
**/
class LazyAddedType {
	public static function injectedMethod(value:String):Int {
		return value.length;
	}
}
