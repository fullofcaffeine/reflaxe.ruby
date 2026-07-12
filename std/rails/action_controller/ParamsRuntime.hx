package rails.action_controller;

/**
	Compiler-recognized params helper.

	RailsHx controllers use this when user-entered strong params need one
	server-owned value, such as `current_user.id`. The Ruby compiler erases this
	facade to normal Rails `params_hash.merge(user_id: current_user.id)` so apps
	do not keep spoofable hidden ownership fields in forms. The shared `TModel`
	on the permitted params and generated field ref makes a cross-model merge a
	Haxe error and preserves the nominal strong-params type without `Dynamic`.
**/
extern class ParamsRuntime {
	public static function mergeField<TModel, TValue>(params:PermittedParams<TModel>, field:rails.active_record.Field<TModel, TValue>,
		value:TValue):PermittedParams<TModel>;
}
