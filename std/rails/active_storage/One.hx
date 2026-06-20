package rails.active_storage;

abstract One<TModel>(String) from String to String {
	public var name(get, never):String;

	public inline function new(name:String) {
		this = name;
	}

	inline function get_name():String {
		return this;
	}

	public static inline function named<TModel>(name:String):One<TModel> {
		return new One(name);
	}

	public function attached(model:TModel):Bool {
		return cast false;
	}

	public function attach(model:TModel, attachable:Attachable):Void {}

	public function attachUnchecked(model:TModel, attachable:Dynamic):Void {}

	public function purge(model:TModel):Void {}
}
