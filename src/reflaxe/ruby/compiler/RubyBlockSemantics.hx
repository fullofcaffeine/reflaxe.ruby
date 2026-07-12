package reflaxe.ruby.compiler;

#if (macro || reflaxe_runtime)
import haxe.macro.Type.TVar;
import haxe.macro.Type.TypedExpr;
import haxe.macro.TypedExprTools;

/**
	Owns the control-flow analysis behind Ruby block lowering.

	Haxe exposes one ordinary typed function parameter. The compiler uses this
	analysis to choose Ruby's implementation detail: direct required callbacks
	can become `yield`, while values that escape their immediate method must be
	captured as `&block`. It also protects Haxe callback-local `return` semantics
	when an inline function is attached to a native Ruby call.
**/
class RubyBlockSemantics {
	/**
		Returns whether a block parameter is used as a first-class value.

		Only a direct call in the declaring method is non-escaping. Assignment,
		return, storage, positional/keyword passing, forwarding, field access, or
		use from a nested function requires a captured Ruby block. The analysis is
		intentionally conservative: an unfamiliar shape captures instead of
		risking a `yield` that changes observable behavior.
	**/
	public static function parameterEscapes(body:TypedExpr, parameter:TVar):Bool {
		var escapes = false;

		function scan(expr:TypedExpr, nestedFunctionDepth:Int):Void {
			if (escapes) {
				return;
			}
			switch (expr.expr) {
				case TCall(callee, args) if (nestedFunctionDepth == 0 && isDirectParameterCall(callee, parameter.id)):
					// The callee occurrence is consumed by `yield`; arguments can still
					// contain an escaping reference and therefore must be inspected.
					for (arg in args) {
						scan(arg, nestedFunctionDepth);
					}
				case TFunction(fn):
					// A direct-looking call inside a closure still captures the outer
					// parameter and cannot use the declaring method's implicit block.
					scan(fn.expr, nestedFunctionDepth + 1);
				case TLocal(variable) if (variable.id == parameter.id):
					escapes = true;
				case _:
					TypedExprTools.iter(expr, child -> scan(child, nestedFunctionDepth));
			}
		}

		scan(body, 0);
		return escapes;
	}

	/** True when `callee` is the named function variable, ignoring transparent wrappers. **/
	public static function isDirectParameterCall(callee:TypedExpr, parameterId:Int):Bool {
		return switch (callee.expr) {
			case TLocal(variable): variable.id == parameterId;
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _): isDirectParameterCall(inner, parameterId);
			case _: false;
		}
	}

	/**
		Returns whether an inline Haxe callback needs strict lambda semantics.

		Ruby `return` inside an ordinary block exits the enclosing method. A Haxe
		`return` exits only its function, so every non-tail return forces a lambda
		that is passed with `&`. A single final return is safe to rewrite as the
		native block's result. Returns inside nested functions belong to those
		functions and do not affect the outer callback's choice.
	**/
	public static function inlineFunctionNeedsLambda(expr:TypedExpr):Bool {
		return switch (expr.expr) {
			case TFunction(fn): hasUnsafeReturn(fn.expr, true);
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _): inlineFunctionNeedsLambda(inner);
			case _: true;
		}
	}

	static function hasUnsafeReturn(expr:TypedExpr, tailPosition:Bool):Bool {
		return switch (expr.expr) {
			case TReturn(value): !tailPosition || (value != null && hasUnsafeReturn(value, false));
			case TBlock(expressions):
				var unsafe = false;
				for (index => child in expressions) {
					if (hasUnsafeReturn(child, tailPosition && index == expressions.length - 1)) {
						unsafe = true;
						break;
					}
				}
				unsafe;
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _):
				hasUnsafeReturn(inner, tailPosition);
			case TFunction(_):
				false;
			case _:
				var unsafe = false;
				TypedExprTools.iter(expr, child -> {
					if (!unsafe && hasUnsafeReturn(child, false)) {
						unsafe = true;
					}
				});
				unsafe;
		}
	}
}
#end
