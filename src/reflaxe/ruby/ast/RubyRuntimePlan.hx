package reflaxe.ruby.ast;

/**
	The closed set of hxruby helpers selected by compiler-owned lowering.

	Keeping helper names nominal prevents a misspelled or newly introduced helper
	from reaching generated Ruby without an explicit semantic-intent decision.
**/
enum abstract RubyRuntimeHelper(String) {
	var ArrayIndexOf = "array_index_of";
	var ArrayInsert = "array_insert";
	var ArrayJoin = "array_join";
	var ArrayLastIndexOf = "array_last_index_of";
	var ArrayRemove = "array_remove";
	var ArrayResize = "array_resize";
	var ArraySlice = "array_slice";
	var ArraySort = "array_sort";
	var ArraySplice = "array_splice";
	var IsOfType = "is_of_type";
	var Iterator = "iterator";
	var KeyValueIterator = "key_value_iterator";
	var MathDivide = "math_divide";
	var NativeIterator = "native_iterator";
	var ParseFloat = "parse_float";
	var ParseInt = "parse_int";
	var ReflectCallMethod = "reflect_call_method";
	var ReflectCompare = "reflect_compare";
	var ReflectCompareMethods = "reflect_compare_methods";
	var ReflectCopy = "reflect_copy";
	var ReflectDeleteField = "reflect_delete_field";
	var ReflectField = "reflect_field";
	var ReflectFields = "reflect_fields";
	var ReflectGetProperty = "reflect_get_property";
	var ReflectHasField = "reflect_has_field";
	var ReflectIsEnumValue = "reflect_is_enum_value";
	var ReflectIsFunction = "reflect_is_function";
	var ReflectIsObject = "reflect_is_object";
	var ReflectMakeVarArgs = "reflect_make_var_args";
	var ReflectSetField = "reflect_set_field";
	var ReflectSetProperty = "reflect_set_property";
	var StringCharAt = "string_char_at";
	var StringCharCodeAt = "string_char_code_at";
	var StringCompare = "string_compare";
	var StringIndexOf = "string_index_of";
	var StringLastIndexOf = "string_last_index_of";
	var StringSplit = "string_split";
	var StringSubstr = "string_substr";
	var StringSubstring = "string_substring";
	var StringToolsFastCodeAt = "string_tools_fast_code_at";
	var StringToolsIsEof = "string_tools_is_eof";
	var StringToolsIsSpace = "string_tools_is_space";
	var StringToolsLpad = "string_tools_lpad";
	var StringToolsRpad = "string_tools_rpad";
	var StringUtf16KeyValueUnits = "string_utf16_key_value_units";
	var StringUtf16Units = "string_utf16_units";
	var Stringify = "stringify";

	public inline function rubyName():String {
		return this;
	}
}

/** Why target execution needs one compiler-selected compatibility helper. **/
enum RubyRuntimeIntent {
	ArraySemantics;
	IteratorCompatibility;
	NumericSemantics;
	PrimitiveConversionSemantics;
	ReflectionSemantics;
	StringSemantics;
	TypeSemantics;
}

/** A request-local helper selection carried by the structural Ruby AST. **/
typedef RubyRuntimeUse = {
	var helper:RubyRuntimeHelper;
	var intent:RubyRuntimeIntent;
}

/**
	Selects and validates runtime intent before helper syntax is printed.

	The mapping is exhaustive over RubyRuntimeHelper. Adding a helper therefore
	requires its semantic owner to be chosen here before any compiler call site
	can construct a valid RubyRuntimeUse.
**/
class RubyRuntimePlan {
	public static function select(helper:RubyRuntimeHelper):RubyRuntimeUse {
		return {
			helper: helper,
			intent: intentFor(helper)
		};
	}

	public static function validate(use:RubyRuntimeUse):Void {
		if (use == null) {
			throw new haxe.Exception("Internal Ruby runtime plan error: missing helper use.");
		}
		var expected = intentFor(use.helper);
		if (use.intent != expected) {
			throw new haxe.Exception("Internal Ruby runtime plan error: helper " + use.helper.rubyName() + " declares " + Std.string(use.intent)
				+ " but requires " + Std.string(expected) + ".");
		}
	}

	static function intentFor(helper:RubyRuntimeHelper):RubyRuntimeIntent {
		return switch (helper) {
			case RubyRuntimeHelper.ArrayIndexOf | RubyRuntimeHelper.ArrayInsert | RubyRuntimeHelper.ArrayJoin | RubyRuntimeHelper.ArrayLastIndexOf | RubyRuntimeHelper.ArrayRemove | RubyRuntimeHelper.ArrayResize | RubyRuntimeHelper.ArraySlice | RubyRuntimeHelper.ArraySort | RubyRuntimeHelper.ArraySplice:
				ArraySemantics;
			case RubyRuntimeHelper.Iterator | RubyRuntimeHelper.KeyValueIterator | RubyRuntimeHelper.NativeIterator:
				IteratorCompatibility;
			case RubyRuntimeHelper.MathDivide:
				NumericSemantics;
			case RubyRuntimeHelper.ParseFloat | RubyRuntimeHelper.ParseInt | RubyRuntimeHelper.Stringify:
				PrimitiveConversionSemantics;
			case RubyRuntimeHelper.ReflectCallMethod | RubyRuntimeHelper.ReflectCompare | RubyRuntimeHelper.ReflectCompareMethods | RubyRuntimeHelper.ReflectCopy | RubyRuntimeHelper.ReflectDeleteField | RubyRuntimeHelper.ReflectField | RubyRuntimeHelper.ReflectFields | RubyRuntimeHelper.ReflectGetProperty | RubyRuntimeHelper.ReflectHasField | RubyRuntimeHelper.ReflectIsEnumValue | RubyRuntimeHelper.ReflectIsFunction | RubyRuntimeHelper.ReflectIsObject | RubyRuntimeHelper.ReflectMakeVarArgs | RubyRuntimeHelper.ReflectSetField | RubyRuntimeHelper.ReflectSetProperty:
				ReflectionSemantics;
			case RubyRuntimeHelper.StringCharAt | RubyRuntimeHelper.StringCharCodeAt | RubyRuntimeHelper.StringCompare | RubyRuntimeHelper.StringIndexOf | RubyRuntimeHelper.StringLastIndexOf | RubyRuntimeHelper.StringSplit | RubyRuntimeHelper.StringSubstr | RubyRuntimeHelper.StringSubstring | RubyRuntimeHelper.StringToolsFastCodeAt | RubyRuntimeHelper.StringToolsIsEof | RubyRuntimeHelper.StringToolsIsSpace | RubyRuntimeHelper.StringToolsLpad | RubyRuntimeHelper.StringToolsRpad | RubyRuntimeHelper.StringUtf16KeyValueUnits | RubyRuntimeHelper.StringUtf16Units:
				StringSemantics;
			case RubyRuntimeHelper.IsOfType:
				TypeSemantics;
		}
	}
}
