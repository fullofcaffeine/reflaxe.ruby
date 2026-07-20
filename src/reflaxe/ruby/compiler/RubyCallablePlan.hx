package reflaxe.ruby.compiler;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import reflaxe.data.ClassFuncArg;
import reflaxe.data.ClassFuncData;
import reflaxe.ruby.compiler.RubyCallableShape.RubyCallableContract;
import reflaxe.ruby.compiler.RubyCallableShape.RubyKeywordFieldContract;

/** Evidence attached to a non-obvious owned-callable lowering choice. **/
typedef RubyCallableDecision = {
	var reason:String;
	var pos:Position;
}

/** Closed definition-side representation for one typed Ruby block parameter. **/
enum RubyOwnedBlockPlan {
	NoOwnedBlock;
	DirectYieldBlock(variableId:Int, decision:RubyCallableDecision);
	CapturedBlock(variableId:Null<Int>, optional:Bool, decision:RubyCallableDecision);
}

/** Closed definition-side representation for one erased keyword carrier. **/
enum RubyOwnedKeywordPlan {
	NoOwnedKeywords;
	DirectKeywordLocals(variableId:Int, fields:Array<RubyKeywordFieldContract>, decision:RubyCallableDecision);
	MaterializedKeywordCarrier(variableId:Int, fields:Array<RubyKeywordFieldContract>, decision:RubyCallableDecision);
}

/**
	The validated, request-local semantic plan for one Haxe-owned Ruby method.

	The callable contract remains the single ABI schema. This plan composes that
	schema with escape and keyword-use analysis once, records why representation
	choices were made, and prevents later AST construction from recomputing two
	related decisions through independent ambient state.
**/
typedef RubyCallableLoweringPlan = {
	var contract:RubyCallableContract;
	var block:RubyOwnedBlockPlan;
	var keywords:RubyOwnedKeywordPlan;
	var pos:Position;
}

/**
	Builds and validates owned callable lowering before RubyAST construction.

	Call-site blocks, arguments, and method values use the existing structural
	call nodes directly. This plan intentionally owns only Haxe-owned method
	definitions, where block escape and keyword materialization must agree for the
	entire body.
**/
class RubyCallablePlan {
	public static function resolve(field:ClassFuncData, contract:RubyCallableContract):RubyCallableLoweringPlan {
		var block = resolveBlock(field, contract);
		var keywords = resolveKeywords(field, contract);
		var plan:RubyCallableLoweringPlan = {
			contract: contract,
			block: block,
			keywords: keywords,
			pos: field.field.pos
		};
		validate(plan);
		return plan;
	}

	public static function directYieldVariableId(plan:RubyCallableLoweringPlan):Null<Int> {
		return switch (plan.block) {
			case DirectYieldBlock(variableId, _): variableId;
			case NoOwnedBlock | CapturedBlock(_, _, _): null;
		}
	}

	public static function capturesBlock(plan:RubyCallableLoweringPlan):Bool {
		return switch (plan.block) {
			case CapturedBlock(_, _, _): true;
			case NoOwnedBlock | DirectYieldBlock(_, _): false;
		}
	}

	public static function materializesKeywords(plan:RubyCallableLoweringPlan):Bool {
		return switch (plan.keywords) {
			case MaterializedKeywordCarrier(_, _, _): true;
			case NoOwnedKeywords | DirectKeywordLocals(_, _, _): false;
		}
	}

	static function resolveBlock(field:ClassFuncData, contract:RubyCallableContract):RubyOwnedBlockPlan {
		if (!contract.hasBlockArg) {
			return NoOwnedBlock;
		}
		var blockArg = argumentAt(field, contract.blockIndex, "block");
		if (!contract.blockOptional && blockArg.tvar != null && !RubyBlockSemantics.parameterEscapes(field.expr, blockArg.tvar)) {
			return DirectYieldBlock(blockArg.tvar.id,
				decision("the required callback is used only through direct calls, so Ruby yield preserves its behavior", field.field.pos));
		}
		var reason = if (contract.blockOptional) {
			"the optional callback must be captured so its absence remains observable";
		} else if (blockArg.tvar == null) {
			"the callback has no stable typed local identity, so conservative capture prevents an unsafe yield";
		} else {
			"the callback escapes direct invocation and must remain a first-class captured block";
		}
		return CapturedBlock(blockArg.tvar == null ? null : blockArg.tvar.id, contract.blockOptional, decision(reason, field.field.pos));
	}

	static function resolveKeywords(field:ClassFuncData, contract:RubyCallableContract):RubyOwnedKeywordPlan {
		if (!contract.hasKwargs) {
			return NoOwnedKeywords;
		}
		var keywordArg = argumentAt(field, contract.kwargsIndex, "keyword carrier");
		var variable = keywordArg.tvar;
		if (variable == null) {
			Context.error("@:rubyKwargs requires a named Haxe parameter so the owned method body can retain its typed carrier semantics.", field.field.pos);
		}
		if (RubyKeywordSemantics.requiresMaterialization(field.expr, variable)) {
			return MaterializedKeywordCarrier(variable.id, contract.keywordFields,
				decision("the method uses its keyword carrier as a first-class Haxe value, so the string-key hash must be reconstructed", field.field.pos));
		}
		return DirectKeywordLocals(variable.id, contract.keywordFields,
			decision("all carrier uses are representable by required keyword locals or the checked optional-key bucket", field.field.pos));
	}

	static function argumentAt(field:ClassFuncData, index:Int, kind:String):ClassFuncArg {
		if (index < 0 || index >= field.args.length) {
			Context.error("Internal Ruby callable plan error: " + kind + " index " + index + " is outside method " + field.field.name + " with "
				+ field.args.length + " parameters.",
				field.field.pos);
		}
		return field.args[index];
	}

	static function validate(plan:RubyCallableLoweringPlan):Void {
		switch (plan.block) {
			case NoOwnedBlock:
				if (plan.contract.hasBlockArg) {
					internalError("a block contract has no block plan", plan.pos);
				}
			case DirectYieldBlock(_, decision):
				if (!plan.contract.hasBlockArg || plan.contract.blockOptional) {
					internalError("direct yield does not match the block contract", plan.pos);
				}
				validateDecision(decision);
			case CapturedBlock(_, optional, decision):
				if (!plan.contract.hasBlockArg || optional != plan.contract.blockOptional) {
					internalError("captured block optionality does not match the block contract", plan.pos);
				}
				validateDecision(decision);
		}
		switch (plan.keywords) {
			case NoOwnedKeywords:
				if (plan.contract.hasKwargs) {
					internalError("a keyword contract has no keyword plan", plan.pos);
				}
			case DirectKeywordLocals(_, fields, decision) | MaterializedKeywordCarrier(_, fields, decision):
				if (!plan.contract.hasKwargs || fields.length != plan.contract.keywordFields.length) {
					internalError("keyword plan fields do not match the callable contract", plan.pos);
				}
				validateDecision(decision);
		}
	}

	static function validateDecision(decision:RubyCallableDecision):Void {
		if (decision == null || decision.reason == null || StringTools.trim(decision.reason) == "") {
			internalError("a non-obvious callable choice has no recorded reason", decision == null ? Context.currentPos() : decision.pos);
		}
	}

	static function decision(reason:String, pos:Position):RubyCallableDecision {
		return {
			reason: reason,
			pos: pos
		};
	}

	static function internalError(message:String, pos:Position):Void {
		Context.error("Internal Ruby callable plan error: " + message + ".", pos);
	}
}
#end
