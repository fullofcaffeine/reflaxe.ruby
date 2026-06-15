package rails.action_controller;

/**
	Typed extern for Rails' `ActionController::ParameterMissing`.

	The controller lifecycle DSL reads the `@:native` Ruby constant so Haxe app
	code can use a type reference instead of a behavior-bearing string.
**/
@:native("ActionController::ParameterMissing")
extern class ParameterMissing {}
