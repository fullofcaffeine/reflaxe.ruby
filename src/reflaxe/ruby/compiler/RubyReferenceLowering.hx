package reflaxe.ruby.compiler;

import reflaxe.ruby.ast.RubyAST.RubyExpr;

/** The shared declaration text and structural expression for one Math value. **/
typedef RubyMathConstantLowering = {
	final declarationCode:String;
	final expression:RubyExpr;
}

/**
	Owns structural Ruby syntax for constants, members, and method references.

	`RubyCompiler` retains source typing and chooses the resolved owner/field.
	This service accepts only those closed target facts, validates constant paths
	through `RubyAST`, and prevents ordinary reference syntax from becoming raw
	text or print-and-reembed logic inside the orchestration entrypoint.
**/
class RubyReferenceLowering {
	/** Wraps an already-resolved Ruby constant path in its validated AST leaf. **/
	public static function constant(path:String):RubyExpr {
		return RubyConstantPath(path);
	}

	/**
		Builds a resolved static owner, preserving the explicit `@:native("self")`
		interop contract used by erased route facades. Every other owner remains a
		validated Ruby constant path.
	**/
	public static function resolvedOwner(path:String):RubyExpr {
		return path == "self" ? RubyLocal("self") : constant(path);
	}

	/** Builds a normal Ruby member read or assignment place. **/
	public static function member(receiver:RubyExpr, name:String):RubyExpr {
		return RubyMember(receiver, name);
	}

	/** Builds `Owner.method(:name)` without assembling target text. **/
	public static function staticMethodValue(ownerPath:String, rubyName:String):RubyExpr {
		return RubyCall(resolvedOwner(ownerPath), "method", [RubySymbol(rubyName)]);
	}

	/** Preserves the Haxe function value used for an array key/value iterator. **/
	public static function iteratorFactory(iteratorExpr:RubyExpr):RubyExpr {
		return RubyLambda([], [RubyExprStatement(iteratorExpr)]);
	}

	/** Returns a checked structural form for compiler-owned static values. **/
	public static function knownStaticValue(typeName:String, fieldName:String):Null<RubyExpr> {
		var math = mathConstant(typeName, fieldName);
		if (math != null) {
			return math.expression;
		}
		return switch [typeName, fieldName] {
			case ["Reflect", "compare"]:
				RubyCall(constant("HXRuby"), "method", [RubySymbol("reflect_compare")]);
			case ["Reflect", "compareMethods"]:
				RubyCall(constant("HXRuby"), "method", [RubySymbol("reflect_compare_methods")]);
			case _: null;
		}
	}

	/**
		Classifies the four Haxe Math values once for the legacy declaration
		boundary and the structural read path, preventing the two consumers from
		drifting while declaration migration remains separate work.
	**/
	public static function mathConstant(typeName:String, fieldName:String):Null<RubyMathConstantLowering> {
		if (typeName != "Math") {
			return null;
		}
		return switch (fieldName) {
			case "PI": math("::Math::PI", constant("::Math::PI"));
			case "NEGATIVE_INFINITY": math("-Float::INFINITY", RubyUnary("-", constant("Float::INFINITY")));
			case "POSITIVE_INFINITY": math("Float::INFINITY", constant("Float::INFINITY"));
			case "NaN": math("Float::NAN", constant("Float::NAN"));
			case _: null;
		}
	}

	static function math(declarationCode:String, expression:RubyExpr):RubyMathConstantLowering {
		return {declarationCode: declarationCode, expression: expression};
	}
}
