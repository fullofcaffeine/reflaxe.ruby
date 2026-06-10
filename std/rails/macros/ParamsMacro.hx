package rails.macros;

import haxe.macro.Expr;
import reflaxe.ruby.naming.RubyNaming;

class ParamsMacro {
	public static macro function requirePermit(params:Expr, root:ExprOf<String>, fields:ExprOf<Array<String>>):Expr {
		var symbols = switch (fields.expr) {
			case EArrayDecl(values):
				[for (value in values) macro ruby.Symbol.of($v{fieldName(value)})];
			case _:
				throw "ParamsMacro.requirePermit expects an array literal of field names.";
				[];
		}
		return macro $params.requireParam($root).permit([$a{symbols}]);
	}

	static function fieldName(expr:Expr):String {
		return switch (expr.expr) {
			case EConst(CString(value, _)):
				RubyNaming.toMethodName(value);
			case _:
				throw "ParamsMacro.requirePermit field names must be string literals.";
				"";
		}
	}
}
