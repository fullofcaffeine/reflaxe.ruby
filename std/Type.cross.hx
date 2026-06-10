package;

enum ValueType {
	TNull;
	TInt;
	TFloat;
	TBool;
	TObject;
	TFunction;
	TClass(c:Class<Dynamic>);
	TEnum(e:Enum<Dynamic>);
	TUnknown;
}

class Type {
	public static function getClass<T>(o:T):Class<T> {
		return cast untyped __ruby__("HXRuby.type_get_class({0})", o);
	}

	public static function getEnum(o:EnumValue):Enum<Dynamic> {
		return cast untyped __ruby__("HXRuby.type_get_enum({0})", o);
	}

	public static function getSuperClass(c:Class<Dynamic>):Class<Dynamic> {
		return cast untyped __ruby__("HXRuby.type_get_super_class({0})", c);
	}

	public static function getClassName(c:Class<Dynamic>):String {
		return cast untyped __ruby__("HXRuby.type_class_name({0})", c);
	}

	public static function getEnumName(e:Enum<Dynamic>):String {
		return cast untyped __ruby__("HXRuby.type_enum_name({0})", e);
	}

	public static function resolveClass(name:String):Class<Dynamic> {
		return cast untyped __ruby__("HXRuby.type_resolve_class({0})", name);
	}

	public static function resolveEnum(name:String):Enum<Dynamic> {
		return cast untyped __ruby__("HXRuby.type_resolve_enum({0})", name);
	}

	public static function createInstance<T>(cl:Class<T>, args:Array<Dynamic>):T {
		return cast untyped __ruby__("HXRuby.type_create_instance({0}, {1})", cl, args);
	}

	public static function createEmptyInstance<T>(cl:Class<T>):T {
		return cast untyped __ruby__("HXRuby.type_create_empty_instance({0})", cl);
	}

	public static function createEnum<T>(e:Enum<T>, constr:String, ?params:Array<Dynamic>):T {
		return cast untyped __ruby__("HXRuby.type_create_enum({0}, {1}, {2})", e, constr, params);
	}

	public static function createEnumIndex<T>(e:Enum<T>, index:Int, ?params:Array<Dynamic>):T {
		return cast untyped __ruby__("HXRuby.type_create_enum_index({0}, {1}, {2})", e, index, params);
	}

	public static function getInstanceFields(c:Class<Dynamic>):Array<String> {
		return cast untyped __ruby__("HXRuby.type_instance_fields({0})", c);
	}

	public static function getClassFields(c:Class<Dynamic>):Array<String> {
		return cast untyped __ruby__("HXRuby.type_class_fields({0})", c);
	}

	public static function getEnumConstructs(e:Enum<Dynamic>):Array<String> {
		return cast untyped __ruby__("HXRuby.type_enum_constructs({0})", e);
	}

	public static function typeof(v:Dynamic):ValueType {
		return cast untyped __ruby__("HXRuby.typeof({0})", v);
	}

	public static function enumEq<T:EnumValue>(a:T, b:T):Bool {
		return cast untyped __ruby__("HXRuby.enum_eq({0}, {1})", a, b);
	}

	public static function enumConstructor(e:EnumValue):String {
		return cast untyped __ruby__("HXRuby.enum_tag({0})", e);
	}

	public static function enumParameters(e:EnumValue):Array<Dynamic> {
		return cast untyped __ruby__("HXRuby.enum_parameters({0})", e);
	}

	public static function enumIndex(e:EnumValue):Int {
		return cast untyped __ruby__("HXRuby.enum_index({0})", e);
	}

	public static function allEnums<T>(e:Enum<T>):Array<T> {
		return cast untyped __ruby__("HXRuby.type_all_enums({0})", e);
	}
}
