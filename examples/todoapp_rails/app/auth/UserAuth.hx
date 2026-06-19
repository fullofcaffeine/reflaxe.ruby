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
// The metadata is compile-time provenance, not runtime code: routes read
// `@:deviseHxRoute`, lifecycle reads `@:deviseHxAuthFilter`, and helper calls
// read `@:deviseHxHelper` so Haxe can lower to normal Devise/Rails helpers.
// Type safety: `scope` carries `DeviseScope<User>`, so sign-in/current-user APIs
// return or accept `User` instead of Dynamic.
// IntelliSense: editors should complete `UserAuth.authenticate`, `current`,
// `currentRequired`, `signedIn`, `signIn`, and `signOut`.
// Ruby/Rails output: calls lower to `authenticate_user!`, `current_user`,
// `user_signed_in?`, `sign_in(:user, user)`, and `sign_out(:user)`.
final class UserAuth {
	@:deviseHxRoute({
		schema: 1,
		routeAuthorable: true,
		resource: "users",
		mappingScope: "user",
		rubyClass: "Models::User",
		haxeModel: "models.User"
	})
	public static final scope:DeviseScope<User> = DeviseScope.of(ScopeName.named("user"), RouteResource.named("users"), User);

	@:deviseHxAuthFilter({schema: 1, mappingScope: "user"})
	public static final authenticate:AuthFilter<User> = Auth.require(scope);

	@:deviseHxHelper({schema: 1, kind: "current", mappingScope: "user"})
	public static inline function current(controller:Base):Null<User> {
		return Auth.current(controller, scope);
	}

	@:deviseHxHelper({schema: 1, kind: "currentRequired", mappingScope: "user"})
	public static inline function currentRequired(controller:Base):User {
		return Auth.currentRequired(controller, scope);
	}

	@:deviseHxHelper({schema: 1, kind: "signedIn", mappingScope: "user"})
	public static inline function signedIn(controller:Base):Bool {
		return Auth.signedIn(controller, scope);
	}

	@:deviseHxHelper({schema: 1, kind: "signIn", mappingScope: "user"})
	public static inline function signIn(controller:Base, resource:User):Void {
		Auth.signIn(controller, scope, resource);
	}

	@:deviseHxHelper({schema: 1, kind: "signOut", mappingScope: "user"})
	public static inline function signOut(controller:Base):Void {
		Auth.signOut(controller, scope);
	}
}
