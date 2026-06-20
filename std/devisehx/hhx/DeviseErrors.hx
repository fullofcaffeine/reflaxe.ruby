package devisehx.hhx;

import devisehx.model.DeviseResource;

/**
	Typed Devise/Rails validation-error facade for HHX templates.

	This is a compiler-erased helper: Haxe verifies that the value is a Devise
	resource, then the Ruby compiler emits ordinary Rails calls such as
	`resource.errors.full_messages`. Devise and ActiveModel still own runtime
	error collection semantics.
**/
extern class DeviseErrors {
	public static function hasAny<TModel>(resource:DeviseResource<TModel>):Bool;
	public static function count<TModel>(resource:DeviseResource<TModel>):Int;
	public static function fullMessages<TModel>(resource:DeviseResource<TModel>):Array<String>;
}
