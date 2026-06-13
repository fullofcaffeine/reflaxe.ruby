package rails.action_controller;

/**
	Typed strong-params permit entry.

	`ParamsMacro.requirePermit(...)` creates these specs from field refs and
	nested object literals; the compiler lowers them to Rails symbols/hashes.
**/
extern class PermitSpec {
	public static function field(name:String):PermitSpec;
	public static function nested(name:String, children:Array<PermitSpec>):PermitSpec;
}
