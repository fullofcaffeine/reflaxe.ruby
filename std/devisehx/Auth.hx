package devisehx;

import rails.action_controller.Base;

/**
	Typed facade over Devise controller helpers.

	These methods are compiler/generator contracts: Rails/Devise owns the runtime
	helpers (`current_user`, `user_signed_in?`, `sign_in`, `sign_out`). RailsHx
	uses the scope token to make those calls type-safe from Haxe.

	`@:rubyNoEmit` marks this as a compile-time facade: the compiler lowers calls
	to ordinary Devise helpers and does not emit a DeviseHx Ruby runtime class.
**/
@:rubyNoEmit
class Auth {
	public static function require<TModel>(scope:DeviseScope<TModel>):AuthFilter<TModel> {
		return AuthFilter.forScope(scope);
	}

	public static function current<TModel>(controller:Base, scope:DeviseScope<TModel>):Null<TModel> {
		return cast null;
	}

	public static function currentRequired<TModel>(controller:Base, scope:DeviseScope<TModel>):TModel {
		return cast null;
	}

	public static function signedIn<TModel>(controller:Base, scope:DeviseScope<TModel>):Bool {
		return false;
	}

	public static function signIn<TModel>(controller:Base, scope:DeviseScope<TModel>, resource:TModel, ?options:SignInOptions):Void {}

	public static function bypassSignIn<TModel>(controller:Base, scope:DeviseScope<TModel>, resource:TModel):Void {}

	public static function signOut<TModel>(controller:Base, scope:DeviseScope<TModel>):Void {}

	public static function signOutAll(controller:Base):Void {}
}
