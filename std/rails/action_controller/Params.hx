package rails.action_controller;

extern class Params {
	@:native("require")
	public function requireParam(key:String):Params;

	public function permit(keys:Array<ruby.Symbol>):Dynamic;
}
