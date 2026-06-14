package rails.action_controller;

typedef RenderOptions = {
	@:optional var json:Dynamic;
	@:optional var plain:String;
	@:optional var html:String;
	@:optional var template:String;
	@:optional var locals:Dynamic;
	@:optional var layout:Dynamic;
	@:optional var status:Status;
}
