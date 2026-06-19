package devisehx.warden;

import devisehx.DeviseScope;

/**
	Narrow typed facade for Warden's proxy.

	Most app code should use `devisehx.Auth`. This type exists for custom auth
	integration seams where an app truly needs Warden while still preserving
	scope/model typing.
**/
extern class WardenProxy {
	public function authenticated<TModel>(scope:DeviseScope<TModel>):Bool;
	public function user<TModel>(scope:DeviseScope<TModel>):Null<TModel>;
}
