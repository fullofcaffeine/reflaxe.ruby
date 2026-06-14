package rails.action_controller;

typedef RedirectOptions = {
	@:optional var action:String;
	@:optional var controller:String;
	@:optional var status:Status;
	@:optional var notice:String;
	@:optional var alert:String;
}
