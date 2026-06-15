package rails.active_record;

/**
	Typed extern for Rails' `ActiveRecord::RecordNotFound`.

	Use this with `rescueFrom(RecordNotFound, notFound)` so the controller
	lifecycle DSL can validate the exception type in Haxe and emit Rails-native
	`rescue_from ActiveRecord::RecordNotFound`.
**/
@:native("ActiveRecord::RecordNotFound")
extern class RecordNotFound {}
