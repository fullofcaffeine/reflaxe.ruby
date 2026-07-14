package devisehx.macros;

/**
	Compiler-erased Ruby fragments produced only after DeviseHx macros validate
	their typed inputs. The generic compiler contract owns substitution; DeviseHx
	continues to own every Ruby template and required Rails module.
**/
@:rubyNoEmit
@:rubyAllowRaw
extern class RubyFragments {
	@:rubyExtensionExpr({schema: 1, templateArg: 0, valueStart: 1})
	public static function value0<T>(template:String):T;

	@:rubyExtensionExpr({schema: 1, templateArg: 0, valueStart: 1})
	public static function value1<T, TValue>(template:String, value:TValue):T;

	@:rubyExtensionExpr({schema: 1, templateArg: 0, valueStart: 1})
	public static function void0(template:String):Void;

	@:rubyExtensionExpr({schema: 1, templateArg: 0, valueStart: 1})
	public static function void1<TValue>(template:String, value:TValue):Void;

	@:rubyExtensionExpr({schema: 1, templateArg: 0, valueStart: 1})
	public static function void2<TValue1, TValue2>(template:String, value1:TValue1, value2:TValue2):Void;

	@:rubyExtensionExpr({schema: 1, templateArg: 0, valueStart: 1})
	public static function void3<TValue1, TValue2, TValue3>(template:String, value1:TValue1, value2:TValue2, value3:TValue3):Void;

	@:railsRequiresFilterArg(0)
	@:rubyExtensionExpr({schema: 1, templateArg: 1, valueStart: 2})
	public static function requiredValue0<T>(filter:String, template:String):T;

	@:railsTestInclude("Devise::Test::IntegrationHelpers")
	@:rubyExtensionExpr({schema: 1, templateArg: 0, valueStart: 1})
	public static function testVoid0(template:String):Void;

	@:railsTestInclude("Devise::Test::IntegrationHelpers")
	@:rubyExtensionExpr({schema: 1, templateArg: 0, valueStart: 1})
	public static function testVoid1<TValue>(template:String, value:TValue):Void;
}
