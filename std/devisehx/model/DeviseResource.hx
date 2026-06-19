package devisehx.model;

/**
	Marker for ActiveRecord models that participate in a Devise scope.

	The marker is intentionally empty: Devise behavior comes from the Ruby
	`devise :...` class macro or an adopted Rails-owned model, not from a
	RailsHx runtime replacement.
**/
interface DeviseResource<TSelf> {}
