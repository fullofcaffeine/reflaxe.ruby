package reflaxe.ruby.compiler;

#if (macro || reflaxe_runtime)
import haxe.macro.Type.FieldAccess;
import haxe.macro.Type.TypedExpr;
import haxe.macro.TypeTools;

/**
	Classifies field reads and calls that need Haxe's Dynamic lookup semantics.

	RubyCompiler supplies the separate native-Array decision because array
	methods have their own lowering owner. Everything else reached through
	`Dynamic` must be read as a value first: anonymous objects are Ruby Hashes,
	while Haxe-owned objects expose bound Ruby Method values through reflection.
**/
class RubyReflectiveFieldSemantics {
	public static function isReflective(target:TypedExpr, access:FieldAccess, isArrayReceiver:Bool):Bool {
		if (isArrayReceiver) {
			return false;
		}
		return switch (access) {
			case FDynamic(_): true;
			case FAnon(_) | FClosure(_, _): isDynamic(target);
			case FInstance(_, _, _) | FStatic(_, _) | FEnum(_, _): false;
		}
	}

	static function isDynamic(expression:TypedExpr):Bool {
		return switch (TypeTools.follow(expression.t)) {
			case TDynamic(_): true;
			case _: false;
		}
	}
}
#end
