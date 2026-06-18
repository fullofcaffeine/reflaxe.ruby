package rails.routing;

/**
	Checked Rails route helper prefix carrier.

	The public DSL currently validates `routeName("admin_posts")` at macro time
	and lowers to a string marker. This abstract exists as the typed destination
	for richer route APIs without exposing plain strings as the semantic concept.
**/
abstract RouteName(String) from String to String {}
