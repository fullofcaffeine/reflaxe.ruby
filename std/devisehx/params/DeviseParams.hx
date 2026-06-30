package devisehx.params;

import devisehx.DeviseScope;
import rails.active_record.Field;

/**
	Typed facade for Devise's `devise_parameter_sanitizer.permit(...)`.

	`permit(...)` accepts generated RailsHx model field refs such as `User.f.name`,
	so Haxe verifies the field owner matches the Devise scope model. The compiler
	erases the facade to normal Devise/Rails Ruby:
	`devise_parameter_sanitizer.permit(:sign_up, keys: [:name])`.

	`@:rubyNoEmit` marks this as an erased typed facade; runtime behavior remains
	Devise's parameter sanitizer, not a generated DeviseHx Ruby class.
**/
@:rubyNoEmit
class DeviseParams {
	public static function permit<TModel>(scope:DeviseScope<TModel>, action:SanitizerAction, keys:Array<Field<TModel, Dynamic>>):Void {}

	/**
		Explicit escape hatch for custom Devise sanitizer keys that are not known
		as typed model fields yet. The compiler accepts literal strings only and
		still emits normal Devise Ruby. Prefer `permit(...)` whenever schema/model
		metadata can generate a field ref.
	**/
	public static function unsafePermit<TModel>(scope:DeviseScope<TModel>, action:SanitizerAction, keys:Array<String>):Void {}
}
