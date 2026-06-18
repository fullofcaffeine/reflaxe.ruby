package rails.routing;

/**
	Checked route regex carrier for `constraints(...)` support.

	Rails route regex constraints have Rails-specific safety rules, including no
	anchors in segment regexes. Keeping a named abstract prevents this API
	from degrading into unconstrained strings.
**/
abstract RouteRegex(String) from String to String {}
