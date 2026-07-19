package reflaxe.ruby.compiler;

import reflaxe.ruby.ast.RubyAST.RubyExpr;
import reflaxe.ruby.ast.RubyAST.RubyStatement;

/**
	Owns the fixed structural Ruby expansion of a typed Haxe `for` loop.

	RubyHx deliberately does not retain a loop plan or semantic loop node: the
	backend has one iterator contract, and ordinary assignment, call, and `while`
	syntax preserves every required fact. The caller remains responsible for the
	source-aware decisions—choosing the iterator expression and allocating both
	locals—while this owner guarantees that the iterable is evaluated exactly once
	and that the loop variable is assigned before each body execution.
**/
class RubyLoopLowering {
	/** Builds `iterator = source; while iterator.has_next; value = iterator.next_`. **/
	public static function compileFor(iteratorName:String, variableName:String, iteratorExpr:RubyExpr, body:Array<RubyStatement>):RubyStatement {
		var iterator = RubyLocal(iteratorName);
		var loopBody:Array<RubyStatement> = [RubyAssign(RubyLocal(variableName), RubyCall(iterator, "next_", []))];
		for (statement in body) {
			loopBody.push(statement);
		}
		return RubyStatementSequence([
			RubyAssign(iterator, iteratorExpr),
			RubyWhileStmt(RubyCall(iterator, "has_next", []), loopBody)
		]);
	}
}
