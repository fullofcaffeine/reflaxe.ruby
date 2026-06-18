package controllers;

import models.User;
import rails.action_controller.Base;

// Shared typed session helper for RailsHx controllers.
//
// Demonstrates: a Haxe-owned helper class wrapping Rails session access without
// app-level raw Ruby.
// Type safety: callers receive `Null<User>` and must handle the unsigned-in
// state; the session key is centralized instead of repeated strings.
// IntelliSense: editors should complete `UserSession.currentUser` and
// `UserSession.currentUserIdKey` from controllers.
// Ruby/Rails output: a small Ruby helper class that calls Rails `session`.
class UserSession {
	public static inline var currentUserIdKey:String = "current_user_id";

	public static function currentUser(controller:Base):Null<User> {
		var storedId = controller.session().get(currentUserIdKey);
		return storedId == null ? User.first() : User.find(cast storedId);
	}
}
