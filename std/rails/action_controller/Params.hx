package rails.action_controller;

extern class Params {
	@:native("require")
	public function requireParam(key:String):Params;

	/**
		Returns Rails' own parameters object with a model scope supplied by the
		`ParamsMacro.requirePermit` expected type. Call the macro for app code; this
		generic primitive exists so the checked expansion never needs `Dynamic`.
	**/
	public function permit<TModel>(keys:Array<PermitSpec>):PermittedParams<TModel>;

	/**
		Typed facade for Rails params hash lookup.

		Haxe authors call `params.get("user_id")`; the Ruby compiler lowers it to
		`params[:user_id]` so app code avoids raw `__ruby__` while still using the
		ordinary ActionController::Parameters API.
	**/
	public function get(key:String):Null<String>;
}
