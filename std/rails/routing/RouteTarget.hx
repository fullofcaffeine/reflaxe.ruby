package rails.routing;

/**
	Compiler-owned Rails route target carrier.

	`rails.macros.RoutesDsl.to(TodosController, index)` expands into this extern
	call. The Ruby compiler reads the literal controller/action pair while
	emitting `config/routes.rb`, then erases the Haxe declaration host. This keeps
	app code typed-ish and avoids a RailsHx runtime router.
**/
extern class RouteTarget {
	public static function to(controller:String, action:String):RouteTarget;
}
