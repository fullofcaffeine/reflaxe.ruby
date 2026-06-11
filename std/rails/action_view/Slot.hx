package rails.action_view;

/**
	Typed RailsHx component slot marker.

	Rails does not have Phoenix-style HEEx slots. RailsHx models reusable
	component content as a captured ActionView buffer passed through a typed
	partial local, so missing slot locals are caught by Haxe before Rails renders.
**/
abstract Slot(Dynamic) from Dynamic to Dynamic {
	public static function content():Slot {
		return null;
	}
}
