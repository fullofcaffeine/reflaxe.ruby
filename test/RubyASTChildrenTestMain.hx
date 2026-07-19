import reflaxe.ruby.ast.RubyAST.RubyCallArgument;
import reflaxe.ruby.ast.RubyAST.RubyExpr;
import reflaxe.ruby.ast.RubyAST.RubyFile;
import reflaxe.ruby.ast.RubyAST.RubyMethodParameter;
import reflaxe.ruby.ast.RubyAST.RubyStatement;
import reflaxe.ruby.ast.RubyASTChildren;
import reflaxe.ruby.ast.RubyASTChildren.RubyStatementChildRole;
import reflaxe.ruby.ast.RubyASTPrinter;
import reflaxe.ruby.ast.RubyRuntimePlan;
import reflaxe.ruby.ast.RubyRuntimePlan.RubyRuntimeHelper;

/** Proves every RubyAST child carrier participates in one exhaustive schema. **/
class RubyASTChildrenTestMain {
	static function main():Void {
		testExpressionChildren();
		testStatementChildren();
		testDeterministicPreorderAndRoles();
		testIdentityMapping();
		testMalformedRequiredCollections();
	}

	static function testExpressionChildren():Void {
		var leaves:Array<RubyExpr> = [
			RubyNil,
			RubyBool(true),
			RubyInt("1"),
			RubyFloat("1.0"),
			RubyString("text"),
			RubySymbol("symbol"),
			RubyLocal("leaf"),
			RubyRawExpr("native_value")
		];
		for (index in 0...leaves.length) {
			assertExprImmediate('expression leaf $index', leaves[index], [], []);
		}

		assertExprImmediate("array", RubyArray([local("array_a"), local("array_b")]), ["local:array_a", "local:array_b"], []);
		assertExprImmediate("hash", RubyHash([{key: "first", value: local("hash_value")}]), ["local:hash_value"], []);
		assertExprImmediate("symbol hash", RubySymbolHash([{key: "first", value: local("symbol_hash_value")}]), ["local:symbol_hash_value"], []);
		assertExprImmediate("index", RubyIndex(local("index_receiver"), local("index_value")), ["local:index_receiver", "local:index_value"], []);
		assertExprImmediate("member", RubyMember(local("member_receiver"), "value"), ["local:member_receiver"], []);
		assertExprImmediate("binary", RubyBinary("+", local("binary_left"), local("binary_right")), ["local:binary_left", "local:binary_right"], []);
		assertExprImmediate("unary", RubyUnary("!", local("unary_value")), ["local:unary_value"], []);
		assertExprImmediate("conditional", RubyConditional(local("condition"), local("then_value"), local("else_value")),
			["local:condition", "local:then_value", "local:else_value"], []);
		assertExprImmediate("begin", RubyBegin([RubyComment("begin_body")]), [], ["comment:begin_body@executable"]);
		assertExprImmediate("begin rescue", RubyBeginRescue([RubyComment("try_body")], [
			{
				exceptionClasses: ["StandardError"],
				binding: "error",
				body: [RubyComment("rescue_body")]
			}
		]), [], ["comment:try_body@executable", "comment:rescue_body@executable"]);
		assertExprImmediate("lambda", RubyLambda(["value"], [RubyComment("lambda_body")]), [], ["comment:lambda_body@executable"]);
		assertExprImmediate("callable lambda", RubyCallableLambda([
			RubyRequiredParameter("required"),
			RubyOptionalParameter("optional", local("optional_default")),
			RubyRestParameter("rest"),
			RubyRequiredKeywordParameter("requiredKeyword"),
			RubyOptionalKeywordParameter("optionalKeyword", local("keyword_default")),
			RubyKeywordRestParameter("keywords"),
			RubyBlockParameter("block")
		],
			[RubyComment("callable_lambda_body")]), ["local:optional_default", "local:keyword_default"],
			["comment:callable_lambda_body@executable"]);
		assertExprImmediate("call", RubyCall(local("call_receiver"), "visit", [local("call_arg_a"), local("call_arg_b")]),
			["local:call_receiver", "local:call_arg_a", "local:call_arg_b"], []);

		var callableArgs:Array<RubyCallArgument> = [
			RubyPositionalArgument(local("positional")),
			RubySplatArgument(local("splat")),
			RubyKeywordArgument("keyword", local("keyword")),
			RubyKeywordSplatArgument(local("keyword_splat")),
			RubyBlockPassArgument(local("block_pass"))
		];
		assertExprImmediate("callable call", RubyCallableCall(local("callable_receiver"), "visit", callableArgs, {
			args: ["item"],
			body: [RubyComment("callable_block_body")]
		}), [
			"local:callable_receiver",
			"local:positional",
			"local:splat",
			"local:keyword",
			"local:keyword_splat",
			"local:block_pass"
		], ["comment:callable_block_body@executable"]);
		assertExprImmediate("yield", RubyYield([local("yield_a"), local("yield_b")]), ["local:yield_a", "local:yield_b"], []);
		assertExprImmediate("case", RubyCase(local("scrutinee"), [
			{
				values: [local("when_a"), local("when_b")],
				body: [RubyComment("case_body")]
			}
		],
			[RubyComment("case_default")]),
			["local:scrutinee", "local:when_a", "local:when_b"], ["comment:case_body@executable", "comment:case_default@executable"]);
		assertExprImmediate("runtime call", RubyRuntimeCall(RubyRuntimePlan.select(RubyRuntimeHelper.ArrayResize), [local("runtime_arg")]),
			["local:runtime_arg"], []);
		assertExprImmediate("exception runtime call", RubyRuntimeCall(RubyRuntimePlan.select(RubyRuntimeHelper.ExceptionCaught), [local("exception_arg")]),
			["local:exception_arg"], []);
		assertExprImmediate("raise", RubyRaise(local("raised_value")), ["local:raised_value"], []);
		assertExprImmediate("bare raise", RubyRaise(), [], []);
	}

	static function testStatementChildren():Void {
		var leaves:Array<RubyStatement> = [RubyNoop, RubyComment("leaf"), RubyRawStatement("native_statement")];
		for (index in 0...leaves.length) {
			assertStatementImmediate('statement leaf $index', leaves[index], [], []);
		}

		assertStatementImmediate("sequence", RubyStatementSequence([RubyComment("sequence_body")]), [], ["comment:sequence_body@executable"]);
		assertStatementImmediate("module", RubyModuleDecl("Demo", [RubyComment("module_body")]), [], ["comment:module_body@declaration"]);
		assertStatementImmediate("class", RubyClassDecl("Demo", [RubyComment("class_body")]), [], ["comment:class_body@declaration"]);
		assertStatementImmediate("class with super", RubyClassDeclWithSuper("Demo", "Base", [RubyComment("super_body")]), [],
			["comment:super_body@declaration"]);
		assertStatementImmediate("method", RubyMethodDecl("visit", [
			RubyOptionalParameter("optional", local("method_default")),
			RubyOptionalKeywordParameter("keyword", local("method_keyword_default"))
		],
			[RubyComment("method_body")]), ["local:method_default", "local:method_keyword_default"],
			["comment:method_body@executable"]);
		assertStatementImmediate("expression", RubyExprStatement(local("statement_expr")), ["local:statement_expr"], []);
		assertStatementImmediate("assign", RubyAssign(local("assign_target"), local("assign_value")), ["local:assign_target", "local:assign_value"], []);
		assertStatementImmediate("return", RubyReturn(local("return_value")), ["local:return_value"], []);
		assertStatementImmediate("empty return", RubyReturn(), [], []);
		assertStatementImmediate("if", RubyIfStmt(local("if_condition"), [RubyComment("if_then")], [RubyComment("if_else")]), ["local:if_condition"],
			["comment:if_then@executable", "comment:if_else@executable"]);
		assertStatementImmediate("while", RubyWhileStmt(local("while_condition"), [RubyComment("while_body")]), ["local:while_condition"],
			["comment:while_body@executable"]);
	}

	static function testDeterministicPreorderAndRoles():Void {
		var file:RubyFile = {
			modulePath: ["Demo"],
			statements: [
				RubyModuleDecl("Outer", [
					RubyClassDecl("Inner", [
						RubyMethodDecl("run", [RubyOptionalParameter("limit", local("default_limit"))], [
							RubyIfStmt(local("condition"), [RubyExprStatement(RubyArray([local("then_value")]))],
								[RubyWhileStmt(local("loop_condition"), [RubyReturn(local("loop_value"))])])
						])
					])
				])
			]
		};
		var events = new Array<String>();
		RubyASTChildren.walkFilePre(file, (statement, role) -> events.push("S:" + statementToken(statement) + "@" + roleToken(role)),
			expr -> events.push("E:" + exprToken(expr)));
		eqArray("deterministic preorder", events, [
			"S:module:Outer@declaration",
			"S:class:Inner@declaration",
			"S:method:run@declaration",
			"E:local:default_limit",
			"S:if@executable",
			"E:local:condition",
			"S:expression@executable",
			"E:array",
			"E:local:then_value",
			"S:while@executable",
			"E:local:loop_condition",
			"S:return@executable",
			"E:local:loop_value"
		]);
	}

	static function testIdentityMapping():Void {
		var expr = RubyCase(local("identity_scrutinee"), [
			{
				values: [RubyInt("1")],
				body: [RubyExprStatement(RubyString("one"))]
			}
		], [RubyExprStatement(RubyString("other"))]);
		var mappedExpr = RubyASTChildren.mapExprImmediate(expr, child -> child, (statement, _) -> statement);
		eq("expression identity mapping", RubyASTPrinter.printExpr(mappedExpr), RubyASTPrinter.printExpr(expr));

		var exceptionExpr = RubyBeginRescue([RubyExprStatement(RubyCall(null, "work", []))], [
			{
				exceptionClasses: ["StandardError"],
				binding: "error",
				body: [RubyExprStatement(RubyRaise(RubyLocal("error")))]
			}
		]);
		var mappedExceptionExpr = RubyASTChildren.mapExprImmediate(exceptionExpr, child -> child, (statement, _) -> statement);
		eq("exception expression identity mapping", RubyASTPrinter.printExpr(mappedExceptionExpr), RubyASTPrinter.printExpr(exceptionExpr));

		var statement = RubyMethodDecl("identity", [RubyOptionalParameter("value", RubyInt("1"))], [RubyReturn(local("value"))]);
		var mappedStatement = RubyASTChildren.mapStatementImmediate(statement, child -> child, (child, _) -> child);
		eq("statement identity mapping", printStatement(mappedStatement), printStatement(statement));

		var file:RubyFile = {modulePath: ["Identity"], statements: [RubyClassDecl("Identity", [statement])]};
		var mappedFile = RubyASTChildren.mapFileImmediate(file, (child, _) -> child);
		eq("file identity mapping", RubyASTPrinter.printFile(mappedFile), RubyASTPrinter.printFile(file));
	}

	static function testMalformedRequiredCollections():Void {
		fails("array child list", () -> RubyASTPrinter.printExpr(RubyArray(null)), "a Ruby array must have a child list");
		fails("hash child list", () -> RubyASTPrinter.printExpr(RubyHash(null)), "a Ruby hash must have a child list");
		fails("hash field", () -> RubyASTPrinter.printExpr(RubyHash([null])), "a Ruby hash field cannot be null");
		fails("statement sequence child list", () -> printStatement(RubyStatementSequence(null)), "a Ruby statement sequence must have a child list");
		fails("call argument", () -> RubyASTPrinter.printExpr(RubyCallableCall(null, "visit", [null])), "a Ruby call argument cannot be null");
		fails("method parameter", () -> printStatement(RubyMethodDecl("visit", [null], [])), "a Ruby method parameter cannot be null");
		fails("case branch", () -> RubyASTPrinter.printExpr(RubyCase(RubyNil, [null], null)), "a Ruby case branch cannot be null");
		fails("begin rescue body", () -> RubyASTPrinter.printExpr(RubyBeginRescue(null, [])), "a Ruby begin/rescue expression must have a child list");
		fails("rescue list", () -> RubyASTPrinter.printExpr(RubyBeginRescue([], null)), "a Ruby begin/rescue expression must have a child list");
		fails("empty rescue list", () -> RubyASTPrinter.printExpr(RubyBeginRescue([], [])), "must have at least one rescue arm");
		fails("null rescue arm", () -> RubyASTPrinter.printExpr(RubyBeginRescue([], [null])), "a Ruby rescue arm cannot be null");
		fails("rescue body", () -> RubyASTPrinter.printExpr(RubyBeginRescue([], [{exceptionClasses: ["StandardError"], binding: null, body: null}])),
			"a Ruby rescue arm must have a child list");
		fails("empty rescue classes", () -> RubyASTPrinter.printExpr(RubyBeginRescue([], [{exceptionClasses: [], binding: null, body: []}])),
			"must name at least one exception class");
		fails("invalid rescue class", () -> RubyASTPrinter.printExpr(RubyBeginRescue([], [{exceptionClasses: ["not_a_constant"], binding: null, body: []}])),
			"invalid rescue exception constant");
		fails("invalid rescue binding",
			() -> RubyASTPrinter.printExpr(RubyBeginRescue([], [{exceptionClasses: ["StandardError"], binding: "BadBinding", body: []}])),
			"invalid rescue binding local");
	}

	static function assertExprImmediate(label:String, expr:RubyExpr, expectedExprs:Array<String>, expectedStatements:Array<String>):Void {
		var exprs = new Array<String>();
		var statements = new Array<String>();
		RubyASTChildren.walkExprImmediate(expr, child -> exprs.push(exprToken(child)),
			(statement, role) -> statements.push(statementToken(statement) + "@" + roleToken(role)));
		eqArray(label + " expression children", exprs, expectedExprs);
		eqArray(label + " statement children", statements, expectedStatements);
	}

	static function assertStatementImmediate(label:String, statement:RubyStatement, expectedExprs:Array<String>, expectedStatements:Array<String>):Void {
		var exprs = new Array<String>();
		var statements = new Array<String>();
		RubyASTChildren.walkStatementImmediate(statement, child -> exprs.push(exprToken(child)),
			(child, role) -> statements.push(statementToken(child) + "@" + roleToken(role)));
		eqArray(label + " expression children", exprs, expectedExprs);
		eqArray(label + " statement children", statements, expectedStatements);
	}

	static function local(name:String):RubyExpr {
		return RubyLocal(name);
	}

	static function roleToken(role:RubyStatementChildRole):String {
		return switch (role) {
			case DeclarationBody: "declaration";
			case ExecutableBody: "executable";
		}
	}

	static function statementToken(statement:RubyStatement):String {
		return switch (statement) {
			case RubyNoop: "noop";
			case RubyComment(text): "comment:" + text;
			case RubyRawStatement(_): "raw";
			case RubyStatementSequence(_): "sequence";
			case RubyModuleDecl(name, _): "module:" + name;
			case RubyClassDecl(name, _): "class:" + name;
			case RubyClassDeclWithSuper(name, _, _): "class-super:" + name;
			case RubyMethodDecl(name, _, _): "method:" + name;
			case RubyExprStatement(_): "expression";
			case RubyAssign(_, _): "assign";
			case RubyReturn(_): "return";
			case RubyIfStmt(_, _, _): "if";
			case RubyWhileStmt(_, _): "while";
		}
	}

	static function exprToken(expr:RubyExpr):String {
		return switch (expr) {
			case RubyNil: "nil";
			case RubyBool(_): "bool";
			case RubyInt(_): "int";
			case RubyFloat(_): "float";
			case RubyString(_): "string";
			case RubySymbol(_): "symbol";
			case RubyLocal(name): "local:" + name;
			case RubyArray(_): "array";
			case RubyHash(_): "hash";
			case RubySymbolHash(_): "symbol-hash";
			case RubyIndex(_, _): "index";
			case RubyMember(_, _): "member";
			case RubyBinary(_, _, _): "binary";
			case RubyUnary(_, _): "unary";
			case RubyConditional(_, _, _): "conditional";
			case RubyBegin(_): "begin";
			case RubyBeginRescue(_, _): "begin-rescue";
			case RubyLambda(_, _): "lambda";
			case RubyCallableLambda(_, _): "callable-lambda";
			case RubyCall(_, name, _): "call:" + name;
			case RubyCallableCall(_, name, _, _): "callable-call:" + name;
			case RubyYield(_): "yield";
			case RubyCase(_, _, _): "case";
			case RubyRuntimeCall(_, _): "runtime-call";
			case RubyRaise(_): "raise";
			case RubyRawExpr(_): "raw";
		}
	}

	static function printStatement(statement:RubyStatement):String {
		return RubyASTPrinter.printFile({modulePath: [], statements: [statement]});
	}

	static function eqArray(label:String, actual:Array<String>, expected:Array<String>):Void {
		eq(label, actual.join(" | "), expected.join(" | "));
	}

	static function eq(label:String, actual:String, expected:String):Void {
		if (actual != expected) {
			throw new haxe.Exception(label + ': expected "' + expected + '", got "' + actual + '"');
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
