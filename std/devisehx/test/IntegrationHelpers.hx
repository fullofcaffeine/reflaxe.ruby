package devisehx.test;

import devisehx.DeviseScope;

/**
	Typed placeholders for Devise test helpers.

	Vanilla Rails/Minitest/RSpec remains first-class. These helpers let generated
	Haxe-authored tests reuse typed Devise scopes before lowering to normal
	Devise test helper calls.
**/
class IntegrationHelpers {
	public static function signIn<TModel>(scope:DeviseScope<TModel>, resource:TModel):Void {}

	public static function signOut<TModel>(scope:DeviseScope<TModel>):Void {}
}
