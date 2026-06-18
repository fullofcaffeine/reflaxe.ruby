package rails.routing;

/**
	Known Rails resource action token.

	RoutesDsl accepts bare Haxe identifiers such as `[index, show, create]` for
	Rails-like ergonomics, then validates those identifiers against controller
	methods. This enum abstract records the canonical action vocabulary for
	future typed overloads and documentation.
**/
enum abstract ResourceAction(String) to String {
	var index = "index";
	var show = "show";
	var newAction = "new";
	var edit = "edit";
	var create = "create";
	var update = "update";
	var destroy = "destroy";
}
