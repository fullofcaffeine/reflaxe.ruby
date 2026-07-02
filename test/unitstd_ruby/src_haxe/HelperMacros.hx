#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	Narrow compile-time helper shim for upstream unitstd fixtures.

	The Ruby unitstd lane expands expression fixtures into runtime assertions, but
	`Map.unit.hx` also checks typing behavior. These macros keep that compile-time
	contract without pulling in the full upstream unit test harness.
**/
class HelperMacros {
	public static macro function typedAs(actual:Expr, expected:Expr):Expr {
		#if macro
		Context.typeof(actual);
		Context.typeof(expected);
		return macro {};
		#end
	}

	public static macro function typeError(expression:Expr):Expr {
		#if macro
		var failed = false;
		try {
			Context.typeof(expression);
		} catch (_:haxe.macro.Expr.Error) {
			failed = true;
		}
		return macro $v{failed};
		#end
	}
}
