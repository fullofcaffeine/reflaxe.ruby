package devisehx.test;

import devisehx.DeviseScope;

/**
	Typed Devise test helpers for Haxe-authored Rails tests.

	Vanilla Rails/Minitest/RSpec remains first-class. These helpers let generated
	Haxe-authored tests reuse typed Devise scopes before the compiler lowers them
	to normal Devise test helper calls such as `sign_in(:user, user)`. The scope
	must be a direct generated field like `UserAuth.scope` so the compiler can
	read the metadata without evaluating runtime Haxe values.
**/
class IntegrationHelpers {
	public static function signIn<TModel>(scope:DeviseScope<TModel>, resource:TModel):Void {}

	public static function signOut<TModel>(scope:DeviseScope<TModel>):Void {}
}
