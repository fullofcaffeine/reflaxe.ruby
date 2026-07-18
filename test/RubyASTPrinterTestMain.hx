import reflaxe.ruby.ast.RubyAST.RubyBlock;
import reflaxe.ruby.ast.RubyAST.RubyCallArgument;
import reflaxe.ruby.ast.RubyAST.RubyExpr;
import reflaxe.ruby.ast.RubyAST.RubyMethodParameter;
import reflaxe.ruby.ast.RubyAST.RubyStatement;
import reflaxe.ruby.ast.RubyASTPrinter;
import reflaxe.ruby.ast.RubyRuntimePlan;
import reflaxe.ruby.ast.RubyRuntimePlan.RubyRuntimeHelper;
import reflaxe.ruby.ast.RubyRuntimePlan.RubyRuntimeIntent;
import reflaxe.ruby.ast.RubyRuntimePlan.RubyRuntimeUse;

/** Verifies that structured callable nodes own Ruby ABI punctuation and layout. **/
class RubyASTPrinterTestMain {
	static function main():Void {
		var parameters:Array<RubyMethodParameter> = [
			RubyRequiredParameter("value"),
			RubyOptionalParameter("limit", RubyInt("2")),
			RubyRestParameter("items"),
			RubyRequiredKeywordParameter("name"),
			RubyOptionalKeywordParameter("active", RubyBool(true)),
			RubyKeywordRestParameter("options"),
			RubyBlockParameter("block")
		];
		var method = RubyMethodDecl("visit", parameters, [RubyExprStatement(RubyYield([RubyLocal("value")]))]);
		eq("structured method", printStatement(method), "def visit(value, limit = 2, *items, name:, active: true, **options, &block)\n  yield(value)\nend\n");
		eq("zero-argument yield", RubyASTPrinter.printExpr(RubyYield([])), "yield");
		eq("structured index", RubyASTPrinter.printExpr(RubyIndex(RubyLocal("values"), RubyInt("1"))), "values[1]");
		eq("structured member", RubyASTPrinter.printExpr(RubyMember(RubyLocal("color"), "__hx_index")), "color.__hx_index");
		eq("statement sequence", printStatement(RubyStatementSequence([
			RubyAssign(RubyLocal("first"), RubyInt("1")),
			RubyAssign(RubyLocal("second"), RubyInt("2"))
		])), "first = 1\nsecond = 2\n");

		var callArgs:Array<RubyCallArgument> = [
			RubyPositionalArgument(RubyInt("1")),
			RubySplatArgument(RubyLocal("items")),
			RubyKeywordArgument("name", RubyString("ruby")),
			RubyKeywordSplatArgument(RubyLocal("options")),
			RubyBlockPassArgument(RubyLocal("callback"))
		];
		eq("structured call", RubyASTPrinter.printExpr(RubyCallableCall(RubyLocal("target"), "visit", callArgs)),
			'target.visit(1, *items, name: "ruby", **options, &callback)');
		eq("callable adapter lambda", RubyASTPrinter.printExpr(RubyCallableLambda([RubyRestParameter("haxe_args")], [
			RubyComment("Adapt positional carriers."),
			RubyExprStatement(RubyCallableCall(RubyLocal("target"), "visit", [
				RubySplatArgument(RubyLocal("haxe_args")),
				RubyBlockPassArgument(RubyLocal("block"))
			]))
		])),
			"->(*haxe_args) do\n  # Adapt positional carriers.\n  target.visit(*haxe_args, &block)\nend");

		var projected = RubyBegin([
			RubyComment("Evaluate the typed keyword carrier once."),
			RubyAssign(RubyLocal("source"), RubyCall(null, "options", [])),
			RubyAssign(RubyLocal("keywords"), RubySymbolHash([
				{
					key: "required",
					value: RubyIndex(RubyLocal("source"), RubyString("required"))
				}
			])),
			RubyIfStmt(RubyCall(RubyLocal("source"), "key?", [RubyString("optional")]), [
				RubyAssign(RubyIndex(RubyLocal("keywords"), RubySymbol("optional")), RubyIndex(RubyLocal("source"), RubyString("optional")))
			]),
			RubyExprStatement(RubyLocal("keywords"))
		]);
		eq("single-evaluation keyword projection",
			RubyASTPrinter.printExpr(RubyCallableCall(RubyLocal("target"), "configure", [RubyKeywordSplatArgument(projected)])),
			'target.configure(**begin\n  # Evaluate the typed keyword carrier once.\n  source = options()\n  keywords = {required: source["required"]}\n  if source.key?("optional")\n    keywords[:optional] = source["optional"]\n  end\n  keywords\nend)');
		eq("conditional optional keyword",
			RubyASTPrinter.printExpr(RubyConditional(RubyBool(true), RubySymbolHash([{key: "optional", value: RubyNil}]), RubySymbolHash([]))),
			"(true ? {optional: nil} : {})");
		eq("structured begin", RubyASTPrinter.printExpr(RubyBegin([
			RubyAssign(RubyLocal("value"), RubyInt("1")),
			RubyExprStatement(RubyLocal("value"))
		])), "begin\n  value = 1\n  value\nend");
		eq("structured case", RubyASTPrinter.printExpr(RubyCase(RubyLocal("value"), [
			{
				values: [RubyInt("1"), RubyInt("2")],
				body: [RubyExprStatement(RubyString("small"))]
			}
		],
			[RubyExprStatement(RubyString("other"))])), 'case value\nwhen 1, 2\n  "small"\nelse\n  "other"\nend');
		eq("typed runtime use",
			RubyASTPrinter.printExpr(RubyRuntimeCall(RubyRuntimePlan.select(RubyRuntimeHelper.ArrayResize), [RubyLocal("values"), RubyInt("3")])),
			"HXRuby.array_resize(values, 3)");
		eq("writer expression", RubyASTPrinter.printExpr(RubyCall(RubyLocal("target"), "value=", [RubyInt("1")])), "(target.value = 1)");
		eq("writer statement", printStatement(RubyExprStatement(RubyCall(RubyLocal("target"), "value=", [RubyInt("1")]))), "target.value = 1\n");
		eq("writer expression precedence", RubyASTPrinter.printExpr(RubyBinary("+", RubyCall(RubyLocal("target"), "value=", [RubyInt("1")]), RubyInt("2"))),
			"((target.value = 1) + 2)");
		eq("native binary operator", RubyASTPrinter.printExpr(RubyCall(RubyLocal("instant"), "+", [RubyFloat("60.0")])), "(instant + 60.0)");
		eq("structured native binary operator",
			RubyASTPrinter.printExpr(RubyCallableCall(RubyLocal("instant"), "-", [RubyPositionalArgument(RubyLocal("earlier"))])), "(instant - earlier)");

		var block:RubyBlock = {
			args: ["item"],
			body: [RubyExprStatement(RubyCall(RubyLocal("item"), "to_s", []))]
		};
		eq("native block", RubyASTPrinter.printExpr(RubyCallableCall(RubyLocal("items"), "each", [], block)), "items.each { |item| item.to_s() }");

		var multilineBlock:RubyBlock = {
			args: ["item"],
			body: [
				RubyExprStatement(RubyCall(null, "prepare", [RubyLocal("item")])),
				RubyExprStatement(RubyCall(null, "finish", [RubyLocal("item")]))
			]
		};
		var returnedBlockCall = RubyMethodDecl("visit", [], [RubyReturn(RubyCallableCall(RubyLocal("items"), "each", [], multilineBlock))]);
		eq("returned multiline block", printStatement(returnedBlockCall),
			"def visit()\n  return items.each do |item|\n    prepare(item)\n    finish(item)\n  end\nend\n");

		var invalidRuntime:RubyRuntimeUse = {
			helper: RubyRuntimeHelper.ArrayResize,
			intent: RubyRuntimeIntent.ReflectionSemantics
		};
		fails("runtime intent mismatch", () -> RubyASTPrinter.printExpr(RubyRuntimeCall(invalidRuntime, [])), "requires ArraySemantics");
		fails("declaration in expression", () -> RubyASTPrinter.printExpr(RubyBegin([RubyMethodDecl("nested", [], [RubyExprStatement(RubyNil)])])),
			"declaration reached an executable");
	}

	static function printStatement(statement:RubyStatement):String {
		return RubyASTPrinter.printFile({modulePath: [], statements: [statement]});
	}

	static function eq(label:String, actual:String, expected:String):Void {
		if (actual != expected) {
			throw label + ': expected "' + expected + '", got "' + actual + '"';
		}
	}

	static function fails(label:String, run:Void->String, expectedMessage:String):Void {
		try {
			run();
			throw new haxe.Exception(label + ": expected validation failure");
		} catch (error:haxe.Exception) {
			if (error.message.indexOf(expectedMessage) == -1) {
				throw new haxe.Exception(label + ': expected "' + expectedMessage + '", got "' + error.message + '"');
			}
		}
	}
}
