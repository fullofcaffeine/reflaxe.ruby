package rails.routing;

/**
	Typed route-segment argument for generated Rails route helper externs.

	Rails route helpers accept scalar IDs and, for polymorphic/model-like helpers,
	objects that Rails can turn into `to_param`. This abstract erases to the
	plain Ruby value (`to Dynamic`) so generated code still calls normal Rails
	helpers, but generated Haxe route externs no longer expose app-facing
	`Dynamic`.

	`@:from` keeps the common `Routes.todoPath(1)` and `Routes.todoPath("1")`
	authoring path ergonomic. Model/object routing is deliberately explicit via
	`RouteParam.model(todo)`, which marks the Rails runtime boundary where the
	object must provide Rails' normal route-param behavior.
**/
abstract RouteParam(Dynamic) to Dynamic {
	public inline function new(value:Dynamic) {
		this = value;
	}

	@:from
	public static inline function fromInt(value:Int):RouteParam {
		return new RouteParam(value);
	}

	@:from
	public static inline function fromString(value:String):RouteParam {
		return new RouteParam(value);
	}

	public static inline function model<T>(value:T):RouteParam {
		return new RouteParam(value);
	}
}
