package rails.active_storage;

/*
	Typed facade for Rails' ActiveStorage::Filename value object.

	Keeping filenames distinct from plain strings makes blob metadata APIs more
	self-documenting while still lowering to Rails' normal `filename.to_s` when
	app code asks for the string value.
 */
@:native("ActiveStorage::Filename")
extern class Filename {
	@:native("to_s")
	public function toString():String;
}
