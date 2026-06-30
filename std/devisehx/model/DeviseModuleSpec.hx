package devisehx.model;

typedef DatabaseAuthenticatableOptions = {
	?authenticationKeys:Array<String>
}

typedef RegisterableOptions = {}
typedef RecoverableOptions = {}
typedef RememberableOptions = {}
typedef ValidatableOptions = {}

typedef ConfirmableOptions = {
	?reconfirmable:Bool
}

typedef LockableOptions = {
	?strategy:String
}

typedef TimeoutableOptions = {
	?timeoutInSeconds:Int
}

typedef OmniauthableOptions = {
	providers:Array<String>
}

/**
	Typed Devise model module specification.

	Known constructors are safe defaults. `UnsafeCustom` is deliberately loud so
	custom Devise modules remain reviewable and do not gain fake schema/type
	guarantees.

	`@:rubyNoEmit` makes this enum a compile-time token set only; Devise module
	symbols are emitted into the Rails model instead of a Ruby enum runtime.
**/
@:rubyNoEmit
enum DeviseModuleSpec {
	DatabaseAuthenticatable(?options:DatabaseAuthenticatableOptions);
	Registerable(?options:RegisterableOptions);
	Recoverable(?options:RecoverableOptions);
	Rememberable(?options:RememberableOptions);
	Validatable(?options:ValidatableOptions);
	Confirmable(?options:ConfirmableOptions);
	Lockable(?options:LockableOptions);
	Trackable;
	Timeoutable(?options:TimeoutableOptions);
	Omniauthable(options:OmniauthableOptions);
	UnsafeCustom(name:String);
}
