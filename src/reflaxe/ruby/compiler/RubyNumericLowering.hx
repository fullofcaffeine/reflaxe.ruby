package reflaxe.ruby.compiler;

import reflaxe.ruby.ast.RubyAST.RubyExpr;
import reflaxe.ruby.ast.RubyAST.RubyStatement;
import reflaxe.ruby.ast.RubyRuntimePlan;
import reflaxe.ruby.ast.RubyRuntimePlan.RubyRuntimeHelper;

/**
	Owns structural Ruby calls for numeric operations whose Haxe and Ruby
	semantics differ.

	Ruby `%` uses floor-modulo, while Haxe remainder keeps the dividend's sign;
	Ruby also raises for a floating zero divisor where Haxe produces `NaN`.
	Portable builds therefore select one closed numeric runtime intent before
	printing instead of teaching the printer to repair an ordinary `%` node.
**/
class RubyNumericLowering {
	/** Builds the validated runtime call that preserves Haxe remainder semantics. **/
	public static function remainder(left:RubyExpr, right:RubyExpr):RubyExpr {
		return RubyRuntimeCall(RubyRuntimePlan.select(RubyRuntimeHelper.MathRemainder), [left, right]);
	}

	/** Preserves both the writeback and result of an expression-valued compound assignment. **/
	public static function assignedResult(target:RubyExpr, value:RubyExpr):RubyExpr {
		return RubyBegin([RubyAssign(target, value), RubyExprStatement(target)]);
	}
}
