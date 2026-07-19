package reflaxe.ruby.ast;

import reflaxe.ruby.ast.RubyAST.RubyBlock;
import reflaxe.ruby.ast.RubyAST.RubyCallArgument;
import reflaxe.ruby.ast.RubyAST.RubyCaseBranch;
import reflaxe.ruby.ast.RubyAST.RubyExpr;
import reflaxe.ruby.ast.RubyAST.RubyFile;
import reflaxe.ruby.ast.RubyAST.RubyHashField;
import reflaxe.ruby.ast.RubyAST.RubyMethodParameter;
import reflaxe.ruby.ast.RubyAST.RubyRescueClause;
import reflaxe.ruby.ast.RubyAST.RubyStatement;

/** The lexical role a child statement body has in structural Ruby syntax. **/
enum RubyStatementChildRole {
	DeclarationBody;
	ExecutableBody;
}

/**
	Authoritative immediate-child and scope schema for `RubyAST`.

	Every switch is deliberately exhaustive and has no catch-all. Adding or
	changing an AST constructor must therefore make an explicit child/scope
	decision here before generic validation, walking, or later analyses can
	silently treat the new structure as a leaf. Raw Ruby nodes are intentionally
	opaque leaves because the compiler has no authority to inspect their text.
**/
class RubyASTChildren {
	/** Maps each immediate statement child of a file in declaration context. **/
	public static function mapFileImmediate(file:RubyFile, mapStatement:(RubyStatement, RubyStatementChildRole) -> RubyStatement):RubyFile {
		return {
			modulePath: file.modulePath,
			statements: mapStatements(file.statements, DeclarationBody, mapStatement)
		};
	}

	/** Visits each immediate file statement in declaration context. **/
	public static function walkFileImmediate(file:RubyFile, visitStatement:(RubyStatement, RubyStatementChildRole) -> Void):Void {
		mapFileImmediate(file, (statement, role) -> {
			visitStatement(statement, role);
			return statement;
		});
	}

	/**
		Rebuilds exactly the immediate AST children of one statement.

		The statement callback receives the lexical role owned by the parent. It
		does not inherit an ambient caller role: a method body is executable even
		when the method declaration itself appears in a class declaration body.
	**/
	public static function mapStatementImmediate(statement:RubyStatement, mapExpr:RubyExpr->RubyExpr,
			mapStatement:(RubyStatement, RubyStatementChildRole) -> RubyStatement):RubyStatement {
		return switch (statement) {
			case RubyNoop | RubyComment(_) | RubyRawStatement(_):
				statement;
			case RubyStatementSequence(body):
				RubyStatementSequence(mapStatements(body, ExecutableBody, mapStatement));
			case RubyModuleDecl(name, body):
				RubyModuleDecl(name, mapStatements(body, DeclarationBody, mapStatement));
			case RubyClassDecl(name, body):
				RubyClassDecl(name, mapStatements(body, DeclarationBody, mapStatement));
			case RubyClassDeclWithSuper(name, superclass, body):
				RubyClassDeclWithSuper(name, superclass, mapStatements(body, DeclarationBody, mapStatement));
			case RubyMethodDecl(name, args, body):
				RubyMethodDecl(name, mapMethodParameters(args, mapExpr), mapStatements(body, ExecutableBody, mapStatement));
			case RubyExprStatement(expr):
				RubyExprStatement(mapExpr(expr));
			case RubyAssign(target, value):
				RubyAssign(mapExpr(target), mapExpr(value));
			case RubyReturn(value):
				RubyReturn(value == null ? null : mapExpr(value));
			case RubyIfStmt(cond, thenBody, elseBody):
				RubyIfStmt(mapExpr(cond), mapStatements(thenBody, ExecutableBody, mapStatement),
					elseBody == null ? null : mapStatements(elseBody, ExecutableBody, mapStatement));
			case RubyWhileStmt(cond, body):
				RubyWhileStmt(mapExpr(cond), mapStatements(body, ExecutableBody, mapStatement));
		}
	}

	/** Rebuilds exactly the immediate AST children of one expression. **/
	public static function mapExprImmediate(expr:RubyExpr, mapExpr:RubyExpr->RubyExpr,
			mapStatement:(RubyStatement, RubyStatementChildRole) -> RubyStatement):RubyExpr {
		return switch (expr) {
			case RubyNil | RubyBool(_) | RubyInt(_) | RubyFloat(_) | RubyString(_) | RubySymbol(_) | RubyLocal(_) | RubyRawExpr(_):
				expr;
			case RubyArray(values):
				RubyArray(mapExprs(values, mapExpr));
			case RubyHash(fields):
				RubyHash(mapHashFields(fields, mapExpr));
			case RubySymbolHash(fields):
				RubySymbolHash(mapHashFields(fields, mapExpr));
			case RubyIndex(receiver, index):
				RubyIndex(mapExpr(receiver), mapExpr(index));
			case RubyMember(receiver, name):
				RubyMember(mapExpr(receiver), name);
			case RubyBinary(op, left, right):
				RubyBinary(op, mapExpr(left), mapExpr(right));
			case RubyUnary(op, value):
				RubyUnary(op, mapExpr(value));
			case RubyConditional(cond, thenExpr, elseExpr):
				RubyConditional(mapExpr(cond), mapExpr(thenExpr), mapExpr(elseExpr));
			case RubyBegin(body):
				RubyBegin(mapStatements(body, ExecutableBody, mapStatement));
			case RubyBeginRescue(body, rescues):
				RubyBeginRescue(mapStatements(body, ExecutableBody, mapStatement), mapRescueClauses(rescues, mapStatement));
			case RubyLambda(args, body):
				RubyLambda(args, mapStatements(body, ExecutableBody, mapStatement));
			case RubyCallableLambda(args, body):
				RubyCallableLambda(mapMethodParameters(args, mapExpr), mapStatements(body, ExecutableBody, mapStatement));
			case RubyCall(receiver, name, args):
				RubyCall(receiver == null ? null : mapExpr(receiver), name, mapExprs(args, mapExpr));
			case RubyCallableCall(receiver, name, args, block):
				RubyCallableCall(receiver == null ? null : mapExpr(receiver), name, mapCallArguments(args, mapExpr),
					block == null ? null : mapBlockImmediate(block, mapStatement));
			case RubyYield(args):
				RubyYield(mapExprs(args, mapExpr));
			case RubyCase(scrutinee, branches, defaultBody):
				RubyCase(mapExpr(scrutinee), mapCaseBranches(branches, mapExpr, mapStatement),
					defaultBody == null ? null : mapStatements(defaultBody, ExecutableBody, mapStatement));
			case RubyRuntimeCall(use, args):
				RubyRuntimeCall(use, mapExprs(args, mapExpr));
			case RubyRaise(exception):
				RubyRaise(exception == null ? null : mapExpr(exception));
		}
	}

	/** Maps the expression child, if any, of one structured method parameter. **/
	public static function mapMethodParameterImmediate(parameter:RubyMethodParameter, mapExpr:RubyExpr->RubyExpr):RubyMethodParameter {
		return switch (parameter) {
			case RubyRequiredParameter(_) | RubyRestParameter(_) | RubyRequiredKeywordParameter(_) | RubyKeywordRestParameter(_) | RubyBlockParameter(_):
				parameter;
			case RubyOptionalParameter(name, defaultValue):
				RubyOptionalParameter(name, mapExpr(defaultValue));
			case RubyOptionalKeywordParameter(name, defaultValue):
				RubyOptionalKeywordParameter(name, mapExpr(defaultValue));
		}
	}

	/** Maps the expression child of one structured callable argument. **/
	public static function mapCallArgumentImmediate(argument:RubyCallArgument, mapExpr:RubyExpr->RubyExpr):RubyCallArgument {
		return switch (argument) {
			case RubyPositionalArgument(value): RubyPositionalArgument(mapExpr(value));
			case RubySplatArgument(value): RubySplatArgument(mapExpr(value));
			case RubyKeywordArgument(name, value): RubyKeywordArgument(name, mapExpr(value));
			case RubyKeywordSplatArgument(value): RubyKeywordSplatArgument(mapExpr(value));
			case RubyBlockPassArgument(value): RubyBlockPassArgument(mapExpr(value));
		}
	}

	/** Maps the executable statement children of one native Ruby block. **/
	public static function mapBlockImmediate(block:RubyBlock, mapStatement:(RubyStatement, RubyStatementChildRole) -> RubyStatement):RubyBlock {
		return {
			args: block.args,
			body: mapStatements(block.body, ExecutableBody, mapStatement)
		};
	}

	/** Maps the expression child of one Ruby hash field. **/
	public static function mapHashFieldImmediate(field:RubyHashField, mapExpr:RubyExpr->RubyExpr):RubyHashField {
		return {
			key: field.key,
			value: mapExpr(field.value)
		};
	}

	/** Maps the values and executable statement body of one Ruby case branch. **/
	public static function mapCaseBranchImmediate(branch:RubyCaseBranch, mapExpr:RubyExpr->RubyExpr,
			mapStatement:(RubyStatement, RubyStatementChildRole) -> RubyStatement):RubyCaseBranch {
		return {
			values: mapExprs(branch.values, mapExpr),
			body: mapStatements(branch.body, ExecutableBody, mapStatement)
		};
	}

	/** Maps the executable statement children of one native Ruby rescue arm. **/
	public static function mapRescueClauseImmediate(clause:RubyRescueClause,
			mapStatement:(RubyStatement, RubyStatementChildRole) -> RubyStatement):RubyRescueClause {
		return {
			exceptionClasses: clause.exceptionClasses,
			binding: clause.binding,
			body: mapStatements(clause.body, ExecutableBody, mapStatement)
		};
	}

	/** Visits each immediate child in the same deterministic order used by mapping. **/
	public static function walkStatementImmediate(statement:RubyStatement, visitExpr:RubyExpr->Void,
			visitStatement:(RubyStatement, RubyStatementChildRole) -> Void):Void {
		mapStatementImmediate(statement, expr -> {
			visitExpr(expr);
			return expr;
		}, (child, role) -> {
			visitStatement(child, role);
			return child;
		});
	}

	/** Visits each immediate child in the same deterministic order used by mapping. **/
	public static function walkExprImmediate(expr:RubyExpr, visitExpr:RubyExpr->Void, visitStatement:(RubyStatement, RubyStatementChildRole) -> Void):Void {
		mapExprImmediate(expr, child -> {
			visitExpr(child);
			return child;
		}, (statement, role) -> {
			visitStatement(statement, role);
			return statement;
		});
	}

	/** Walks a complete file preorder, including nested expressions and statements. **/
	public static function walkFilePre(file:RubyFile, visitStatement:(RubyStatement, RubyStatementChildRole) -> Void, visitExpr:RubyExpr->Void):Void {
		if (file == null || file.statements == null) {
			return;
		}
		walkFileImmediate(file, (statement, role) -> walkStatementPre(statement, role, visitStatement, visitExpr));
	}

	/** Walks one statement subtree preorder while preserving every child-body role. **/
	public static function walkStatementPre(statement:RubyStatement, role:RubyStatementChildRole,
			visitStatement:(RubyStatement, RubyStatementChildRole) -> Void, visitExpr:RubyExpr->Void):Void {
		visitStatement(statement, role);
		walkStatementImmediate(statement, expr -> walkExprPre(expr, visitExpr, visitStatement),
			(child, childRole) -> walkStatementPre(child, childRole, visitStatement, visitExpr));
	}

	/** Walks one expression subtree preorder, entering every structural statement body. **/
	public static function walkExprPre(expr:RubyExpr, visitExpr:RubyExpr->Void, visitStatement:(RubyStatement, RubyStatementChildRole) -> Void):Void {
		visitExpr(expr);
		walkExprImmediate(expr, child -> walkExprPre(child, visitExpr, visitStatement),
			(statement, role) -> walkStatementPre(statement, role, visitStatement, visitExpr));
	}

	static function mapExprs(values:Array<RubyExpr>, mapExpr:RubyExpr->RubyExpr):Array<RubyExpr> {
		return values == null ? null : [for (value in values) mapExpr(value)];
	}

	static function mapStatements(statements:Array<RubyStatement>, role:RubyStatementChildRole,
			mapStatement:(RubyStatement, RubyStatementChildRole) -> RubyStatement):Array<RubyStatement> {
		return statements == null ? null : [for (statement in statements) mapStatement(statement, role)];
	}

	static function mapMethodParameters(parameters:Array<RubyMethodParameter>, mapExpr:RubyExpr->RubyExpr):Array<RubyMethodParameter> {
		return parameters == null ? null : [for (parameter in parameters) mapMethodParameterImmediate(parameter, mapExpr)];
	}

	static function mapCallArguments(arguments:Array<RubyCallArgument>, mapExpr:RubyExpr->RubyExpr):Array<RubyCallArgument> {
		return arguments == null ? null : [for (argument in arguments) mapCallArgumentImmediate(argument, mapExpr)];
	}

	static function mapHashFields(fields:Array<RubyHashField>, mapExpr:RubyExpr->RubyExpr):Array<RubyHashField> {
		return fields == null ? null : [for (field in fields) mapHashFieldImmediate(field, mapExpr)];
	}

	static function mapCaseBranches(branches:Array<RubyCaseBranch>, mapExpr:RubyExpr->RubyExpr,
			mapStatement:(RubyStatement, RubyStatementChildRole) -> RubyStatement):Array<RubyCaseBranch> {
		return branches == null ? null : [for (branch in branches) mapCaseBranchImmediate(branch, mapExpr, mapStatement)];
	}

	static function mapRescueClauses(clauses:Array<RubyRescueClause>,
			mapStatement:(RubyStatement, RubyStatementChildRole) -> RubyStatement):Array<RubyRescueClause> {
		return clauses == null ? null : [for (clause in clauses) mapRescueClauseImmediate(clause, mapStatement)];
	}
}
