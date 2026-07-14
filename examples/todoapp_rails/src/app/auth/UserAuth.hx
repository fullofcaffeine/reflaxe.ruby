package app.auth;

import devisehx.Auth;
import devisehx.AuthFilter;
import devisehx.DeviseScope;
import devisehx.RouteResource;
import devisehx.ScopeName;
import models.User;
import rails.action_controller.Base;

// App-local DeviseHx contract for the todoapp's User scope.
//
// Demonstrates: the generated contract shape apps get from DeviseHx adoption.
// DeviseHx reads `@:deviseHxRoute`; generic Rails/compiler metadata carries the
// validated filter and helper shapes without teaching core about Devise.
// Type safety: `scope` carries `DeviseScope<User>`, so sign-in/current-user APIs
// return or accept `User` instead of Dynamic.
// IntelliSense: editors should complete `UserAuth.authenticate`, `current`,
// `currentRequired`, `signedIn`, `signIn`, and `signOut`.
// Ruby/Rails output: calls lower to `authenticate_user!`, `current_user`,
// `user_signed_in?`, `sign_in(:user, user)`, and `sign_out(:user)`.
@:rubyNoEmit
final class UserAuth {
	@:deviseHxRoute({
		schema: 1,
		routeAuthorable: true,
		resource: "users",
		mappingScope: "user",
		rubyClass: "User",
		haxeModel: "models.User"
	})
	public static final scope:DeviseScope<User> = DeviseScope.of(ScopeName.named("user"), RouteResource.named("users"), User);

	@:railsFilterMethod("authenticate_user!")
	public static final authenticate:AuthFilter<User> = Auth.require(scope);

	public static inline function current(controller:Base):Null<User> {
		return Auth.current(controller, scope);
	}

	@:railsRequiresFilter("authenticate_user!")
	public static inline function currentRequired(controller:Base):User {
		return Auth.currentRequired(controller, scope);
	}

	public static inline function signedIn(controller:Base):Bool {
		return Auth.signedIn(controller, scope);
	}

	public static inline function signIn(controller:Base, resource:User):Void {
		Auth.signIn(controller, scope, resource);
	}

	public static inline function signOut(controller:Base):Void {
		Auth.signOut(controller, scope);
	}
}
