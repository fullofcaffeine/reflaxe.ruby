#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Field;
import haxe.macro.Type.TypedExpr;
import reflaxe.ruby.RubyCompiler;
import reflaxe.ruby.ast.RubyASTPrinter;

/**
	Compile-time contract for the residual typed `TFor` path.

	Haxe normalizes ordinary source loops before RubyHx receives them, so the
	runtime fixture alone cannot guarantee that the compiler keeps direct `TFor`
	input structural. This build macro obtains type-correct variable and iterator
	facts from Haxe, assembles the residual typed node explicitly, pre-reserves its
	exact generated iterator name to model an adversarial local collision, and
	verifies the final Ruby shape without adding test-only production behavior.
**/
@:access(reflaxe.ruby.RubyCompiler)
class LoopStructuralContract {
	public static macro function build():Array<Field> {
		var declaration = Context.typeExpr(macro {
			var value:Int = 0;
		});
		var variable = switch (declaration.expr) {
			case TBlock([{expr: TVar(candidate, _)}]):
				candidate;
			case _:
				Context.error("Loop structural contract could not obtain a typed loop variable.", declaration.pos);
				return Context.getBuildFields();
		};
		var iterable = Context.typeExpr(macro [1, 2, 3].iterator());
		var emptyBody = Context.typeExpr(macro {});
		var body:TypedExpr = {
			expr: TBlock([
				{expr: TContinue, t: emptyBody.t, pos: emptyBody.pos},
				{expr: TBreak, t: emptyBody.t, pos: emptyBody.pos}
			]),
			t: emptyBody.t,
			pos: emptyBody.pos
		};
		var loop:TypedExpr = {
			expr: TFor(variable, iterable, body),
			t: emptyBody.t,
			pos: iterable.pos
		};
		var iteratorBase = "hx_iter_value_" + Context.getPosInfos(iterable.pos).min;
		RubyCompiler.localNameScope = null;
		var reserved = RubyCompiler.allocateSyntheticLocalName(iteratorBase);
		if (reserved != iteratorBase) {
			Context.error("Loop structural contract could not reserve the expected iterator base.", loop.pos);
		}
		var output = RubyASTPrinter.printFile({modulePath: [], statements: [RubyCompiler.compileStatement(loop)]});
		RubyCompiler.localNameScope = null;
		var allocated = iteratorBase + "__hx1";
		for (expected in [
			allocated + " = Haxe::Iterators::ArrayIterator.new([1, 2, 3])",
			"while " + allocated + ".has_next()",
			"value = " + allocated + ".next_()",
			"  next",
			"  break"
		]) {
			if (output.indexOf(expected) == -1) {
				Context.error('Structural TFor output is missing `$expected`:\n$output', loop.pos);
			}
		}
		return Context.getBuildFields();
	}
}
#else
class LoopStructuralContract {}
#end
