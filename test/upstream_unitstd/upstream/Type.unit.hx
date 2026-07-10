// Adapted from upstream Type.unit.hx: lexical blocks preserve section-local
// names when this expression fixture expands into the combined Ruby lane.
{
	// getClass
	Type.getClass("foo") == String;
	Type.getClass(new C()) == C;
	Type.getClass([]) == Array;
	Type.getClass(Float) == null;
	Type.getClass(null) == null;
	Type.getClass(Int) == null;
	Type.getClass(Bool) == null;
	Type.getClass({}) == null;
} {
	// getEnum
	Type.getEnum(haxe.macro.Expr.ExprDef.EBreak) == haxe.macro.Expr.ExprDef;
	Type.getEnum(null) == null;
} {
	// getSuperClass
	Type.getSuperClass(String) == null;
	Type.getSuperClass(ClassWithToString) == null;
	Type.getSuperClass(ClassWithToStringChild) == ClassWithToString;
} {
	// getClassName
	Type.getClassName(String) == "String";
	Type.getClassName(C) == "unit.spec.C";
	Type.getClassName(Type.getClass([])) == "Array";
} {
	// getEnumName
	Type.getEnumName(haxe.macro.Expr.ExprDef) == "haxe.macro.ExprDef";
} {
	// resolveClass
	Type.resolveClass("String") == String;
	Type.resolveClass("unit.spec.C") == C;
	Type.resolveClass("MyNonExistingClass") == null;
} {
	// resolveEnum
	Type.resolveEnum("haxe.macro.ExprDef") == haxe.macro.Expr.ExprDef;
	Type.resolveEnum("String") == null;
} {
	// createInstance
	Type.createInstance(String, ["foo"]) == "foo";
	Type.createInstance(C, []).v == "var";
	var c = Type.createInstance(ClassWithCtorDefaultValues, [2, "bar"]);
	c.a == 2;
	c.b == "bar";
	var c2 = Type.createInstance(ClassWithCtorDefaultValues2, [2, "bar"]);
	c2.a == 2;
	c2.b == "bar";
} {
	// createEmptyInstance
	var c = Type.createEmptyInstance(ClassWithCtorDefaultValues);
	c.a == null;
	c.b == null;
	var child = Type.createEmptyInstance(ClassWithCtorDefaultValuesChild);
	child.a == null;
	child.b == null;
} {
	// createEnum
	var e = Type.createEnum(E, "NoArgs");
	e == NoArgs;
	Type.createEnum(E, "NoArgs", []) == NoArgs;
	Type.enumEq(Type.createEnum(E, "OneArg", [1]), OneArg(1)) == true;
	Type.enumEq(Type.createEnum(E, "RecArg", [e]), RecArg(e)) == true;
	Type.enumEq(Type.createEnum(E, "MultipleArgs", [1, "foo"]), MultipleArgs(1, "foo")) == true;
} {
	// createEnumIndex
	var e = Type.createEnumIndex(E, 0);
	e == NoArgs;
	Type.createEnumIndex(E, 0, []) == NoArgs;
	Type.createEnumIndex(E, 0, null) == NoArgs;
	Type.enumEq(Type.createEnumIndex(E, 1, [1]), OneArg(1)) == true;
	Type.enumEq(Type.createEnumIndex(E, 2, [e]), RecArg(e)) == true;
	Type.enumEq(Type.createEnumIndex(E, 3, [1, "foo"]), MultipleArgs(1, "foo")) == true;
	Type.createEnumIndex(EnumFlagTest, 0) == EA;
	Type.createEnumIndex(EnumFlagTest, 1, []) == EB;
	Type.createEnumIndex(EnumFlagTest, 2, null) == EC;
} {
	// getInstanceFields
	var fields = Type.getInstanceFields(C);
	var requiredFields = ["func", "v", "prop"];
	for (field in fields) {
		t(requiredFields.remove(field));
	}
	requiredFields == [];
	var childFields = Type.getInstanceFields(CChild);
	var childRequiredFields = ["func", "v", "prop"];
	for (field in childFields) {
		t(childRequiredFields.remove(field));
	}
	childRequiredFields == [];
} {
	// getClassFields
	var fields = Type.getClassFields(C);
	var requiredFields = ["staticFunc", "staticVar", "staticProp"];
	for (field in fields) {
		t(requiredFields.remove(field));
	}
	requiredFields == [];
	var childFields = Type.getClassFields(CChild);
	var childRequiredFields:Array<String> = [];
	for (field in childFields) {
		t(childRequiredFields.remove(field));
	}
	childRequiredFields == [];
} {
	// getEnumConstructs
	Type.getEnumConstructs(E) == ["NoArgs", "OneArg", "RecArg", "MultipleArgs"];
	Type.getEnumConstructs(EnumFlagTest) == ["EA", "EB", "EC"];
} {
	// enumEq
	Type.enumEq(NoArgs, NoArgs) == true;
	Type.enumEq(OneArg(1), OneArg(1)) == true;
	Type.enumEq(RecArg(OneArg(1)), RecArg(OneArg(1))) == true;
	Type.enumEq(MultipleArgs(1, "foo"), MultipleArgs(1, "foo")) == true;
	Type.enumEq(NoArgs, OneArg(1)) == false;
	Type.enumEq(NoArgs, RecArg(NoArgs)) == false;
	Type.enumEq(NoArgs, MultipleArgs(1, "foo")) == false;
	Type.enumEq(OneArg(1), OneArg(2)) == false;
	Type.enumEq(RecArg(OneArg(1)), RecArg(OneArg(2))) == false;
	Type.enumEq(EA, EA) == true;
	Type.enumEq(EA, EB) == false;
} {
	// enumConstructor
	Type.enumConstructor(NoArgs) == "NoArgs";
	Type.enumConstructor(OneArg(1)) == "OneArg";
	Type.enumConstructor(RecArg(OneArg(1))) == "RecArg";
	Type.enumConstructor(MultipleArgs(1, "foo")) == "MultipleArgs";
	Type.enumConstructor(EC) == "EC";
} {
	// enumParameters
	Type.enumParameters(NoArgs) == [];
	var oneArgParameters:Array<Dynamic> = [1];
	aeq(oneArgParameters, Type.enumParameters(OneArg(1)));
	var recursiveParameters:Array<Dynamic> = [NoArgs];
	aeq(recursiveParameters, Type.enumParameters(RecArg(NoArgs)));
	var multipleParameters:Array<Dynamic> = [1, "foo"];
	aeq(multipleParameters, Type.enumParameters(MultipleArgs(1, "foo")));
	Type.enumParameters(EC) == [];
} {
	// enumIndex
	Type.enumIndex(NoArgs) == 0;
	Type.enumIndex(OneArg(1)) == 1;
	Type.enumIndex(RecArg(OneArg(1))) == 2;
	Type.enumIndex(MultipleArgs(1, "foo")) == 3;
	Type.enumIndex(EB) == 1;
} {
	// allEnums
	Type.allEnums(E) == [NoArgs];
	Type.allEnums(haxe.macro.Expr.ExprDef) == [EBreak, EContinue];
	Type.allEnums(EnumFlagTest) == [EA, EB, EC];
}
