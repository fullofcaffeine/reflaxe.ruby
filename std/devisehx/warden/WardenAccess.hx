package devisehx.warden;

import rails.action_controller.Base;

/**
	Explicit unsafe seam for direct Warden access.

	The name is intentionally loud: direct Warden use is app-specific and should
	not appear in canonical DeviseHx examples unless a later bead adds a checked
	abstraction for that exact case.

	`@:rubyNoEmit` marks the unsafe accessor as an erased Haxe facade over the
	controller's Warden proxy, not a runtime DeviseHx wrapper.
**/
@:rubyNoEmit
class WardenAccess {
	public static function unsafeWarden(controller:Base):WardenProxy {
		return cast null;
	}
}
