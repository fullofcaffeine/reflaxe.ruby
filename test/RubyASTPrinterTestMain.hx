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
import reflaxe.ruby.compiler.RubyInt32Lowering;
import reflaxe.ruby.compiler.RubyLoopLowering;

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
		eq("nested constant path", RubyASTPrinter.printExpr(RubyConstantPath("Main::Worker")), "Main::Worker");
		eq("absolute constant path", RubyASTPrinter.printExpr(RubyConstantPath("::Math::PI")), "::Math::PI");
		eq("simple symbol", RubyASTPrinter.printExpr(RubySymbol("ready")), ":ready");
		eq("bang symbol", RubyASTPrinter.printExpr(RubySymbol("save!")), ":save!");
		eq("predicate symbol", RubyASTPrinter.printExpr(RubySymbol("ready?")), ":ready?");
		eq("writer symbol", RubyASTPrinter.printExpr(RubySymbol("name=")), ":name=");
		eq("quoted symbol", RubyASTPrinter.printExpr(RubySymbol("two words")), ":\"two words\"");
		eq("escaped symbol", RubyASTPrinter.printExpr(RubySymbol("line\n\"quoted\"")), ":\"line\\n\\\"quoted\\\"\"");
		eq("terminal newline symbol", RubyASTPrinter.printExpr(RubySymbol("ready\n")), ":\"ready\\n\"");
		eq("terminal carriage-return symbol", RubyASTPrinter.printExpr(RubySymbol("ready\r")), ":\"ready\\r\"");
		eq("non-interpolating symbol", RubyASTPrinter.printExpr(RubySymbol("#{danger}")), ":\"\\#{danger}\"");
		eq("non-interpolating instance-variable symbol", RubyASTPrinter.printExpr(RubySymbol("#@danger")), ":\"\\#@danger\"");
		var globalInterpolation = "#" + "$" + "danger";
		eq("non-interpolating global-variable symbol", RubyASTPrinter.printExpr(RubySymbol(globalInterpolation)), ":\"\\#" + "$" + "danger\"");
		eq("non-interpolating string", RubyASTPrinter.printExpr(RubyString("#{danger}")), "\"\\#{danger}\"");
		eq("structural Int32 clamp", RubyASTPrinter.printExpr(RubyInt32Lowering.clamp(RubyLocal("value"))),
			"(((value + 0x80000000) % 0x100000000) - 0x80000000)");
		eq("structural Int32 left shift", RubyASTPrinter.printExpr(RubyInt32Lowering.shiftLeft(RubyLocal("value"), RubyLocal("count"))),
			"((((value.to_i() << (count.to_i() & 31)) + 0x80000000) % 0x100000000) - 0x80000000)");
		eq("structural Int32 signed right shift", RubyASTPrinter.printExpr(RubyInt32Lowering.shiftRight(RubyLocal("value"), RubyLocal("count"))),
			"((((value + 0x80000000) % 0x100000000) - 0x80000000) >> (count.to_i() & 31))");
		eq("structural Int32 unsigned right shift", RubyASTPrinter.printExpr(RubyInt32Lowering.shiftRightUnsigned(RubyLocal("value"), RubyLocal("count"))),
			"((value.to_i() & 0xffffffff) >> (count.to_i() & 31))");
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
		eq("structured begin rescue", RubyASTPrinter.printExpr(RubyBeginRescue([RubyExprStatement(RubyCall(null, "work", []))], [
			{
				exceptionClasses: ["StandardError", "RuntimeError"],
				binding: "error",
				body: [RubyExprStatement(RubyMember(RubyLocal("error"), "message"))]
			}
		])),
			"begin\n  work()\nrescue StandardError, RuntimeError => error\n  error.message\nend");
		eq("raise expression", RubyASTPrinter.printExpr(RubyRaise(RubyCall(RubyLocal("HxException"), "new", [RubyString("boom")]))),
			'(raise HxException.new("boom"))');
		eq("raise statement", printStatement(RubyExprStatement(RubyRaise(RubyString("boom")))), 'raise "boom"\n');
		eq("bare re-raise statement", printStatement(RubyExprStatement(RubyRaise())), "raise\n");
		eq("break expression", RubyASTPrinter.printExpr(RubyBreak), "(break)");
		eq("break statement", printStatement(RubyExprStatement(RubyBreak)), "break\n");
		eq("next expression", RubyASTPrinter.printExpr(RubyNext), "(next)");
		eq("next statement", printStatement(RubyExprStatement(RubyNext)), "next\n");
		eq("structural for expansion",
			printStatement(RubyLoopLowering.compileFor("iterator__hx1", "value", RubyCall(null, "build_iterator", []),
				[RubyExprStatement(RubyCall(null, "consume", [RubyLocal("value")]))])),
			"iterator__hx1 = build_iterator()\nwhile iterator__hx1.has_next()\n  value = iterator__hx1.next_()\n  consume(value)\nend\n");
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
		eq("typed exception runtime use",
			RubyASTPrinter.printExpr(RubyRuntimeCall(RubyRuntimePlan.select(RubyRuntimeHelper.ExceptionWrap), [RubyLocal("error")])),
			"HxException.wrap(error)");
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
		eq("raise native block", RubyASTPrinter.printExpr(RubyCallableCall(RubyLocal("items"), "each", [], {
			args: ["item"],
			body: [RubyExprStatement(RubyRaise(RubyString("boom")))]
		})), "items.each do |item|\n  raise \"boom\"\nend");
		eq("next native block", RubyASTPrinter.printExpr(RubyCallableCall(RubyLocal("items"), "each", [], {
			args: ["item"],
			body: [RubyExprStatement(RubyNext)]
		})), "items.each do |item|\n  next\nend");

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
		var invalidExceptionRuntime:RubyRuntimeUse = {
			helper: RubyRuntimeHelper.ExceptionCaught,
			intent: RubyRuntimeIntent.TypeSemantics
		};
		fails("exception runtime intent mismatch", () -> RubyASTPrinter.printExpr(RubyRuntimeCall(invalidExceptionRuntime, [])),
			"requires ExceptionBoundarySemantics");
		fails("declaration in expression", () -> RubyASTPrinter.printExpr(RubyBegin([RubyMethodDecl("nested", [], [RubyExprStatement(RubyNil)])])),
			"declaration reached an executable");
		fails("invalid rescue constant", () -> RubyASTPrinter.printExpr(RubyBeginRescue([], [{exceptionClasses: ["bad"], binding: null, body: []}])),
			"invalid rescue exception constant");
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
