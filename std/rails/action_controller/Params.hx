package rails.action_controller;

extern class Params {
	@:native("require")
	public function requireParam(key:String):Params;

	public function permit(keys:Array<PermitSpec>):Dynamic;

	/**
		Typed facade for Rails params hash lookup.

		Haxe authors call `params.get("user_id")`; the Ruby compiler lowers it to
		`params[:user_id]` so app code avoids raw `__ruby__` while still using the
		ordinary ActionController::Parameters API.
	**/
	public function get(key:String):Null<String>;
}
