package rails.active_storage;

abstract Many<TModel>(String) from String to String {
	public var name(get, never):String;

	public inline function new(name:String) {
		this = name;
	}

	inline function get_name():String {
		return this;
	}

	public static inline function named<TModel>(name:String):Many<TModel> {
		return new Many(name);
	}

	public function attached(model:TModel):Bool {
		return cast false;
	}

	public function attach(model:TModel, attachables:Array<String>):Void {}

	public function attachUnchecked(model:TModel, attachables:Dynamic):Void {}

	public function purge(model:TModel):Void {}
}
