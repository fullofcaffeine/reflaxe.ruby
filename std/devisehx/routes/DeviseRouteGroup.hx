package devisehx.routes;

/**
	Typed Devise route groups for `DeviseRoutes.deviseFor(..., {only/skip: [...]})`.

	These are compile-time route-shaping tokens, not helper predictions. Devise
	still expands the final Rails routes, and RailsHx still generates helper
	externs from the real `rails routes` output.

	`@:rubyNoEmit` keeps the enum as Haxe-only route metadata; generated Rails
	routes contain ordinary `devise_for` options.
**/
@:rubyNoEmit
enum DeviseRouteGroup {
	Sessions;
	Passwords;
	Registrations;
	Confirmations;
	Unlocks;
	OmniauthCallbacks;
}
