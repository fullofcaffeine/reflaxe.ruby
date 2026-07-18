package reflaxe.ruby.ast;

import reflaxe.ruby.ast.RubyAST.RubyCallArgument;
import reflaxe.ruby.ast.RubyAST.RubyExpr;
import reflaxe.ruby.ast.RubyAST.RubyFile;
import reflaxe.ruby.ast.RubyAST.RubyMethodParameter;
import reflaxe.ruby.ast.RubyAST.RubyStatement;

private enum RubyStatementContext {
	DeclarationBody;
	ExecutableBody;
}

/**
	Validates structural Ruby invariants before punctuation is emitted.

	The typed AST already prevents most malformed combinations. This pass owns
	cross-node rules such as keeping declarations out of executable expression
	bodies and ensuring each runtime helper use still agrees with its selected
	semantic intent.
**/
class RubyASTValidator {
	public static function validateFile(file:RubyFile):Void {
		if (file == null || file.statements == null) {
			fail("a Ruby file must have a statement list");
		}
		validateStatements(file.statements, DeclarationBody);
	}

	public static function validateExpr(expr:RubyExpr):Void {
		if (expr == null) {
			fail("an expression cannot be null");
		}
		switch (expr) {
			case RubyNil | RubyBool(_) | RubyInt(_) | RubyFloat(_) | RubyString(_) | RubySymbol(_) | RubyRawExpr(_):
			case RubyLocal(name):
				requireName(name, "local or constant");
			case RubyArray(values):
				validateExprs(values);
			case RubyHash(fields) | RubySymbolHash(fields):
				if (fields != null) {
					for (field in fields) {
						validateExpr(field.value);
					}
				}
			case RubyIndex(receiver, index):
				validateExpr(receiver);
				validateExpr(index);
			case RubyMember(receiver, name):
				validateExpr(receiver);
				if (name == null || !~/^[A-Za-z_][A-Za-z0-9_]*[!?=]?$/.match(name)) {
					fail("invalid Ruby member name " + Std.string(name));
				}
			case RubyBinary(_, left, right):
				validateExpr(left);
				validateExpr(right);
			case RubyUnary(_, value):
				validateExpr(value);
			case RubyConditional(cond, thenExpr, elseExpr):
				validateExpr(cond);
				validateExpr(thenExpr);
				validateExpr(elseExpr);
			case RubyBegin(body):
				validateStatements(body, ExecutableBody);
			case RubyLambda(args, body):
				validateNames(args, "lambda parameter");
				validateStatements(body, ExecutableBody);
			case RubyCallableLambda(args, body):
				validateMethodParameters(args);
				validateStatements(body, ExecutableBody);
			case RubyCall(receiver, name, args):
				if (receiver != null) {
					validateExpr(receiver);
				}
				requireName(name, "call");
				validateExprs(args);
			case RubyCallableCall(receiver, name, args, block):
				if (receiver != null) {
					validateExpr(receiver);
				}
				requireName(name, "call");
				if (args != null) {
					for (arg in args) {
						validateCallArgument(arg);
					}
				}
				if (block != null) {
					validateNames(block.args, "block parameter");
					validateStatements(block.body, ExecutableBody);
				}
			case RubyYield(args):
				validateExprs(args);
			case RubyCase(scrutinee, branches, defaultBody):
				validateExpr(scrutinee);
				if (branches == null) {
					fail("a Ruby case must have a branch list");
				}
				for (branch in branches) {
					if (branch.values == null || branch.values.length == 0) {
						fail("a Ruby case branch must have at least one when value");
					}
					validateExprs(branch.values);
					validateStatements(branch.body, ExecutableBody);
				}
				if (defaultBody != null) {
					validateStatements(defaultBody, ExecutableBody);
				}
			case RubyRuntimeCall(use, args):
				RubyRuntimePlan.validate(use);
				validateExprs(args);
		}
	}

	static function validateStatements(statements:Array<RubyStatement>, context:RubyStatementContext):Void {
		if (statements == null) {
			return;
		}
		for (statement in statements) {
			validateStatement(statement, context);
		}
	}

	static function validateStatement(statement:RubyStatement, context:RubyStatementContext):Void {
		if (statement == null) {
			fail("a statement cannot be null");
		}
		switch (statement) {
			case RubyNoop | RubyComment(_) | RubyRawStatement(_):
			case RubyStatementSequence(body):
				validateStatements(body, ExecutableBody);
			case RubyModuleDecl(name, body) | RubyClassDecl(name, body):
				requireDeclarationContext(context);
				requireName(name, "declaration");
				validateStatements(body, DeclarationBody);
			case RubyClassDeclWithSuper(name, superclass, body):
				requireDeclarationContext(context);
				requireName(name, "declaration");
				requireName(superclass, "superclass");
				validateStatements(body, DeclarationBody);
			case RubyMethodDecl(name, args, body):
				requireDeclarationContext(context);
				requireName(name, "method");
				validateMethodParameters(args);
				validateStatements(body, ExecutableBody);
			case RubyExprStatement(expr):
				validateExpr(expr);
			case RubyAssign(target, value):
				validateExpr(target);
				validateExpr(value);
			case RubyReturn(value):
				if (value != null) {
					validateExpr(value);
				}
			case RubyIfStmt(cond, thenBody, elseBody):
				validateExpr(cond);
				validateStatements(thenBody, ExecutableBody);
				validateStatements(elseBody, ExecutableBody);
			case RubyWhileStmt(cond, body):
				validateExpr(cond);
				validateStatements(body, ExecutableBody);
		}
	}

	static function validateMethodParameters(parameters:Array<RubyMethodParameter>):Void {
		if (parameters == null) {
			return;
		}
		for (parameter in parameters) {
			switch (parameter) {
				case RubyRequiredParameter(name) | RubyRestParameter(name) | RubyRequiredKeywordParameter(name) | RubyKeywordRestParameter(name) |
					RubyBlockParameter(name):
					requireName(name, "method parameter");
				case RubyOptionalParameter(name, defaultValue) | RubyOptionalKeywordParameter(name, defaultValue):
					requireName(name, "method parameter");
					validateExpr(defaultValue);
			}
		}
	}

	static function validateCallArgument(argument:RubyCallArgument):Void {
		switch (argument) {
			case RubyPositionalArgument(value) | RubySplatArgument(value) | RubyKeywordSplatArgument(value) | RubyBlockPassArgument(value):
				validateExpr(value);
			case RubyKeywordArgument(name, value):
				requireName(name, "keyword argument");
				validateExpr(value);
		}
	}

	static function validateExprs(values:Array<RubyExpr>):Void {
		if (values == null) {
			return;
		}
		for (value in values) {
			validateExpr(value);
		}
	}

	static function validateNames(names:Array<String>, kind:String):Void {
		if (names == null) {
			return;
		}
		for (name in names) {
			requireName(name, kind);
		}
	}

	static function requireDeclarationContext(context:RubyStatementContext):Void {
		if (context != DeclarationBody) {
			fail("a declaration reached an executable statement or expression body");
		}
	}

	static function requireName(name:String, kind:String):Void {
		if (name == null || StringTools.trim(name) == "") {
			fail(kind + " name cannot be empty");
		}
	}

	static function fail(message:String):Void {
		throw new haxe.Exception("Internal Ruby AST validation error: " + message + ".");
	}
}
