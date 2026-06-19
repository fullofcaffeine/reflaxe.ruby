package devisehx.mapping;

import devisehx.DeviseScope;
import devisehx.ScopeName;
import devisehx.model.DeviseModuleSpec;

/**
	Typed view of a Devise mapping.

	Devise still owns the runtime mapping object. This extern-shaped contract is
	for generated/adopted Haxe code that needs typed access to deterministic
	mapping facts without dropping to untyped Warden internals.
**/
extern class DeviseMapping<TModel> {
	public var name(default, null):ScopeName;
	public var scope(default, null):DeviseScope<TModel>;
	public var modules(default, null):Array<DeviseModuleSpec>;
}
