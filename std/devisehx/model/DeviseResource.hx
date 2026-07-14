package devisehx.model;

/**
	Marker for ActiveRecord models that participate in a Devise scope.

	The marker is intentionally empty: Devise behavior comes from the Ruby
	`devise :...` class macro or an adopted Rails-owned model, not from a
	RailsHx runtime replacement.

	`@:rubyNoEmit` avoids an empty Ruby marker module while preserving the Haxe
	type bound used by generated DeviseHx contracts.
**/
@:autoBuild(devisehx.macros.DeviseModelMacro.build())
@:rubyNoEmit
interface DeviseResource<TSelf> {}
