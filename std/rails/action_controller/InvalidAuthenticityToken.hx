package rails.action_controller;

/**
	Typed extern for Rails' `ActionController::InvalidAuthenticityToken`.

	Use it in `rescueFrom(InvalidAuthenticityToken, handler)` when a controller
	needs Rails-native CSRF rescue handling without raw Ruby constant strings.
**/
@:native("ActionController::InvalidAuthenticityToken")
extern class InvalidAuthenticityToken {}
