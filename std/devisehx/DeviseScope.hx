package devisehx;

/**
	A generated Devise scope token.

	The token couples a Rails scope name, route resource, and Haxe model type so
	helpers such as `current`, `signIn`, and route/view helpers cannot drift
	across multi-scope apps. Devise still owns runtime mappings; this is a typed
	authoring contract generated from deterministic inventory.

	`@:rubyNoEmit` means generated/app-local scope fields may use this type for
	Haxe checking without creating a DeviseHx runtime constant in Ruby.
**/
@:rubyNoEmit
final class DeviseScope<TModel> {
	public final name:ScopeName;
	public final routeResource:RouteResource;
	public final model:Class<TModel>;

	private function new(name:ScopeName, routeResource:RouteResource, model:Class<TModel>) {
		this.name = name;
		this.routeResource = routeResource;
		this.model = model;
	}

	public static function of<TModel>(name:ScopeName, routeResource:RouteResource, model:Class<TModel>):DeviseScope<TModel> {
		return new DeviseScope(name, routeResource, model);
	}
}
