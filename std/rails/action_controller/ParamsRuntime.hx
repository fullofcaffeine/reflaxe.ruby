package rails.action_controller;

/**
	Compiler-recognized params helper.

	RailsHx controllers use this when user-entered strong params need one
	server-owned value, such as `current_user.id`. The Ruby compiler erases this
	facade to normal Rails `params_hash.merge(user_id: current_user.id)` so apps
	do not keep spoofable hidden ownership fields in forms.
**/
extern class ParamsRuntime {
	public static function mergeField<TField, TValue>(params:Dynamic, field:TField, value:TValue):Dynamic;
}
