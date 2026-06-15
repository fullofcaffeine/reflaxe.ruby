package ruby;

/**
	Typed extern for Ruby's `StandardError`.

	RailsHx lifecycle DSLs read `@:native` exception constants from extern
	classes, which gives Haxe completion/type checking while preserving the
	ordinary Ruby constant in generated code.
**/
@:native("StandardError")
extern class StandardError {}
