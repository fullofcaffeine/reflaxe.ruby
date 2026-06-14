package rails.action_view;

/**
	Typed Rails layout token for controller rendering.

	`Template.layout(ViewClass)` is the preferred path because it ties a layout to
	a RailsHx-owned HHX view class. `Layout.named(...)` is the lower-level checked
	literal boundary for Rails-owned layouts. There is intentionally no
	`from String`: raw layout strings should not bypass path checks.
**/
abstract Layout(String) to String {
	public inline function new(path:String) {
		this = path;
	}

	public static function named(path:String):Layout {
		return new Layout(path);
	}
}
