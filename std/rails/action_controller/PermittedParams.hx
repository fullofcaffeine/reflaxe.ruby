package rails.action_controller;

/**
	Nominal typed view of Rails `ActionController::Parameters` after `permit`.

	`TModel` records the model scope proven by `ParamsMacro.requirePermit`. The
	Ruby value remains Rails' own parameters object: this extern adds no wrapper,
	runtime allocation, field-reading API, or generated constant. ActiveRecord
	write overloads accept the matching `PermittedParams<TModel>` positionally,
	which preserves Rails' strong-params behavior without routing the boundary
	through `Dynamic` or pretending it is a Haxe string-key anonymous object.
**/
@:native("ActionController::Parameters")
extern class PermittedParams<TModel> {}
