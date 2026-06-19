package devisehx.model;

/**
	Ergonomic constants for common Devise module specs.

	Apps can import `devisehx.model.DeviseModule.*` and write
	`[databaseAuthenticatable, recoverable, validatable]`, while the compiler and
	generators still receive typed module specs instead of raw symbols.
**/
class DeviseModule {
	public static final databaseAuthenticatable:DeviseModuleSpec = DatabaseAuthenticatable();
	public static final registerable:DeviseModuleSpec = Registerable();
	public static final recoverable:DeviseModuleSpec = Recoverable();
	public static final rememberable:DeviseModuleSpec = Rememberable();
	public static final validatable:DeviseModuleSpec = Validatable();
	public static final confirmable:DeviseModuleSpec = Confirmable();
	public static final lockable:DeviseModuleSpec = Lockable();
	public static final trackable:DeviseModuleSpec = Trackable;
	public static final timeoutable:DeviseModuleSpec = Timeoutable();

	public static function omniauthable(providers:Array<String>):DeviseModuleSpec {
		return Omniauthable({providers: providers});
	}

	public static function unsafeCustom(name:String):DeviseModuleSpec {
		return UnsafeCustom(name);
	}
}
