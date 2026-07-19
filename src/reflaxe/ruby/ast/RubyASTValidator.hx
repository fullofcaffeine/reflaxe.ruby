package reflaxe.ruby.ast;

import reflaxe.ruby.ast.RubyAST.RubyCallArgument;
import reflaxe.ruby.ast.RubyAST.RubyExpr;
import reflaxe.ruby.ast.RubyAST.RubyFile;
import reflaxe.ruby.ast.RubyAST.RubyMethodParameter;
import reflaxe.ruby.ast.RubyAST.RubyStatement;
import reflaxe.ruby.ast.RubyASTChildren.RubyStatementChildRole;

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
		RubyASTChildren.walkFileImmediate(file, (statement, role) -> validateStatement(statement, role));
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
				requireList(values, "a Ruby array");
			case RubyHash(fields) | RubySymbolHash(fields):
				requireList(fields, "a Ruby hash");
				for (field in fields) {
					if (field == null) {
						fail("a Ruby hash field cannot be null");
					}
				}
			case RubyIndex(_, _):
			case RubyMember(_, name):
				if (name == null || !~/^[A-Za-z_][A-Za-z0-9_]*[!?=]?$/.match(name)) {
					fail("invalid Ruby member name " + Std.string(name));
				}
			case RubyBinary(_, _, _) | RubyUnary(_, _) | RubyConditional(_, _, _) | RubyBegin(_) | RubyRaise(_):
			case RubyBeginRescue(body, rescues):
				requireList(body, "a Ruby begin/rescue expression");
				requireList(rescues, "a Ruby begin/rescue expression");
				if (rescues.length == 0) {
					fail("a Ruby begin/rescue expression must have at least one rescue arm");
				}
				for (rescue in rescues) {
					if (rescue == null) {
						fail("a Ruby rescue arm cannot be null");
					}
					requireList(rescue.body, "a Ruby rescue arm");
					requireList(rescue.exceptionClasses, "a Ruby rescue arm");
					if (rescue.exceptionClasses.length == 0) {
						fail("a Ruby rescue arm must name at least one exception class");
					}
					for (exceptionClass in rescue.exceptionClasses) {
						requireConstantPath(exceptionClass, "rescue exception");
					}
					if (rescue.binding != null) {
						requireLocalName(rescue.binding, "rescue binding");
					}
				}
			case RubyLambda(args, _):
				validateNames(args, "lambda parameter");
			case RubyCallableLambda(args, _):
				validateMethodParameterShapes(args);
			case RubyCall(_, name, _):
				requireName(name, "call");
			case RubyCallableCall(_, name, args, block):
				requireName(name, "call");
				validateCallArgumentShapes(args);
				if (block != null) {
					validateNames(block.args, "block parameter");
				}
			case RubyYield(_):
			case RubyCase(_, branches, _):
				if (branches == null) {
					fail("a Ruby case must have a branch list");
				}
				for (branch in branches) {
					if (branch == null) {
						fail("a Ruby case branch cannot be null");
					}
					if (branch.values == null || branch.values.length == 0) {
						fail("a Ruby case branch must have at least one when value");
					}
				}
			case RubyRuntimeCall(use, _):
				RubyRuntimePlan.validate(use);
		}
		RubyASTChildren.walkExprImmediate(expr, validateExpr, (statement, role) -> validateStatement(statement, role));
	}

	static function validateStatement(statement:RubyStatement, context:RubyStatementChildRole):Void {
		if (statement == null) {
			fail("a statement cannot be null");
		}
		switch (statement) {
			case RubyNoop | RubyComment(_) | RubyRawStatement(_):
			case RubyStatementSequence(body):
				requireList(body, "a Ruby statement sequence");
			case RubyModuleDecl(name, _) | RubyClassDecl(name, _):
				requireDeclarationContext(context);
				requireName(name, "declaration");
			case RubyClassDeclWithSuper(name, superclass, _):
				requireDeclarationContext(context);
				requireName(name, "declaration");
				requireName(superclass, "superclass");
			case RubyMethodDecl(name, args, _):
				requireDeclarationContext(context);
				requireName(name, "method");
				validateMethodParameterShapes(args);
			case RubyExprStatement(_) | RubyAssign(_, _) | RubyReturn(_) | RubyIfStmt(_, _, _) | RubyWhileStmt(_, _):
		}
		RubyASTChildren.walkStatementImmediate(statement, validateExpr, (child, role) -> validateStatement(child, role));
	}

	static function validateMethodParameterShapes(parameters:Array<RubyMethodParameter>):Void {
		if (parameters == null) {
			return;
		}
		for (parameter in parameters) {
			if (parameter == null) {
				fail("a Ruby method parameter cannot be null");
			}
			switch (parameter) {
				case RubyRequiredParameter(name) | RubyRestParameter(name) | RubyRequiredKeywordParameter(name) | RubyKeywordRestParameter(name) |
					RubyBlockParameter(name):
					requireName(name, "method parameter");
				case RubyOptionalParameter(name, _) | RubyOptionalKeywordParameter(name, _):
					requireName(name, "method parameter");
			}
		}
	}

	static function validateCallArgumentShapes(arguments:Array<RubyCallArgument>):Void {
		if (arguments == null) {
			return;
		}
		for (argument in arguments) {
			if (argument == null) {
				fail("a Ruby call argument cannot be null");
			}
			switch (argument) {
				case RubyPositionalArgument(_) | RubySplatArgument(_) | RubyKeywordSplatArgument(_) | RubyBlockPassArgument(_):
				case RubyKeywordArgument(name, _):
					requireName(name, "keyword argument");
			}
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

	static function requireDeclarationContext(context:RubyStatementChildRole):Void {
		if (context != DeclarationBody) {
			fail("a declaration reached an executable statement or expression body");
		}
	}

	static function requireList<T>(values:Array<T>, kind:String):Void {
		if (values == null) {
			fail(kind + " must have a child list");
		}
	}

	static function requireName(name:String, kind:String):Void {
		if (name == null || StringTools.trim(name) == "") {
			fail(kind + " name cannot be empty");
		}
	}

	static function requireConstantPath(name:String, kind:String):Void {
		if (name == null || !~/^(?:::)?[A-Z][A-Za-z0-9_]*(?:::[A-Z][A-Za-z0-9_]*)*$/.match(name)) {
			fail("invalid " + kind + " constant " + Std.string(name));
		}
	}

	static function requireLocalName(name:String, kind:String):Void {
		if (name == null || !~/^[a-z_][A-Za-z0-9_]*$/.match(name)) {
			fail("invalid " + kind + " local " + Std.string(name));
		}
	}

	static function fail(message:String):Void {
		throw new haxe.Exception("Internal Ruby AST validation error: " + message + ".");
	}
}
