package devisehx.hhx;

import devisehx.DeviseScope;

/**
	Typed Devise route helpers for Rails HHX templates.

	These functions are compiler-erased authoring facades. The Ruby compiler
	requires the `scope` argument to be a direct generated field such as
	`UserAuth.scope`, reads its `@:deviseHxRoute` metadata, and emits ordinary
	Rails helpers like `new_user_session_path` or `destroy_user_session_path`.
	This keeps HHX code typed without reimplementing Devise routing at runtime.
**/
extern class AuthLinks {
	public static function newSessionPath<TModel>(scope:DeviseScope<TModel>):String;
	public static function sessionPath<TModel>(scope:DeviseScope<TModel>):String;
	public static function destroySessionPath<TModel>(scope:DeviseScope<TModel>):String;
	public static function newRegistrationPath<TModel>(scope:DeviseScope<TModel>):String;
	public static function editRegistrationPath<TModel>(scope:DeviseScope<TModel>):String;
	public static function registrationPath<TModel>(scope:DeviseScope<TModel>):String;
	public static function cancelRegistrationPath<TModel>(scope:DeviseScope<TModel>):String;
	public static function newPasswordPath<TModel>(scope:DeviseScope<TModel>):String;
	public static function editPasswordPath<TModel>(scope:DeviseScope<TModel>):String;
	public static function passwordPath<TModel>(scope:DeviseScope<TModel>):String;

	public static function signInPath<TModel>(scope:DeviseScope<TModel>):String;
	public static function signOutPath<TModel>(scope:DeviseScope<TModel>):String;
	public static function signUpPath<TModel>(scope:DeviseScope<TModel>):String;
}
