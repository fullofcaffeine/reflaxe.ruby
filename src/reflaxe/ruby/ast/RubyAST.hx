package reflaxe.ruby.ast;

import reflaxe.ruby.ast.RubyRuntimePlan.RubyRuntimeUse;

/** Closed structural Ruby syntax between typed Haxe lowering and printing. **/
typedef RubyFile = {
	var modulePath:Array<String>;
	var statements:Array<RubyStatement>;
}

enum RubyStatement {
	RubyNoop;
	RubyComment(text:String);
	RubyRawStatement(code:String);
	RubyStatementSequence(body:Array<RubyStatement>);
	RubyModuleDecl(name:String, body:Array<RubyStatement>);
	RubyClassDecl(name:String, body:Array<RubyStatement>);
	RubyClassDeclWithSuper(name:String, superclass:String, body:Array<RubyStatement>);
	RubyMethodDecl(name:String, args:Array<RubyMethodParameter>, body:Array<RubyStatement>);
	RubyExprStatement(expr:RubyExpr);
	RubyAssign(target:RubyExpr, value:RubyExpr);
	RubyReturn(?value:RubyExpr);
	RubyIfStmt(cond:RubyExpr, thenBody:Array<RubyStatement>, ?elseBody:Array<RubyStatement>);
	RubyWhileStmt(cond:RubyExpr, body:Array<RubyStatement>);
}

enum RubyExpr {
	RubyNil;
	RubyBool(value:Bool);
	RubyInt(value:String);
	RubyFloat(value:String);
	RubyString(value:String);
	RubySymbol(value:String);
	RubyLocal(name:String);
	RubyArray(values:Array<RubyExpr>);
	RubyHash(fields:Array<RubyHashField>);
	RubySymbolHash(fields:Array<RubyHashField>);
	RubyIndex(receiver:RubyExpr, index:RubyExpr);
	RubyMember(receiver:RubyExpr, name:String);
	RubyBinary(op:String, left:RubyExpr, right:RubyExpr);
	RubyUnary(op:String, expr:RubyExpr);
	RubyConditional(cond:RubyExpr, thenExpr:RubyExpr, elseExpr:RubyExpr);
	RubyBegin(body:Array<RubyStatement>);
	RubyBeginRescue(body:Array<RubyStatement>, rescues:Array<RubyRescueClause>);
	RubyLambda(args:Array<String>, body:Array<RubyStatement>);
	RubyCallableLambda(args:Array<RubyMethodParameter>, body:Array<RubyStatement>);
	RubyCall(?receiver:RubyExpr, name:String, args:Array<RubyExpr>);
	RubyCallableCall(?receiver:RubyExpr, name:String, args:Array<RubyCallArgument>, ?block:RubyBlock);
	RubyYield(args:Array<RubyExpr>);
	RubyCase(scrutinee:RubyExpr, branches:Array<RubyCaseBranch>, defaultBody:Null<Array<RubyStatement>>);
	RubyRuntimeCall(use:RubyRuntimeUse, args:Array<RubyExpr>);
	RubyRaise(?exception:RubyExpr);
	RubyRawExpr(code:String);
}

/**
	Structured Ruby method parameters used by the callable ABI.

	Keeping parameter kinds nominal prevents keyword, rest, and block markers from
	being assembled as ambiguous strings in the compiler. The printer is the only
	owner of their Ruby punctuation.
**/
enum RubyMethodParameter {
	RubyRequiredParameter(name:String);
	RubyOptionalParameter(name:String, defaultValue:RubyExpr);
	RubyRestParameter(name:String);
	RubyRequiredKeywordParameter(name:String);
	RubyOptionalKeywordParameter(name:String, defaultValue:RubyExpr);
	RubyKeywordRestParameter(name:String);
	RubyBlockParameter(name:String);
}

/** Structured argument kinds for calls whose Ruby ABI is not purely positional. **/
enum RubyCallArgument {
	RubyPositionalArgument(value:RubyExpr);
	RubySplatArgument(value:RubyExpr);
	RubyKeywordArgument(name:String, value:RubyExpr);
	RubyKeywordSplatArgument(value:RubyExpr);
	RubyBlockPassArgument(value:RubyExpr);
}

/**
	A native Ruby block attached to a call.

	This is intentionally distinct from `RubyLambda`: a block participates in a
	method call and has Ruby block control/arity behavior, while a lambda is a
	first-class strict callable value.
**/
typedef RubyBlock = {
	var args:Array<String>;
	var body:Array<RubyStatement>;
}

typedef RubyHashField = {
	var key:String;
	var value:RubyExpr;
}

/** One structural Ruby case arm with one or more when values. **/
typedef RubyCaseBranch = {
	var values:Array<RubyExpr>;
	var body:Array<RubyStatement>;
}

/**
	One native Ruby `rescue` arm.

	Exception classes and the optional binding are syntax decisions. Haxe catch
	type dispatch remains structural inside `body` because Ruby rescues native
	exception carriers while Haxe dispatches over the possibly wrapped value.
**/
typedef RubyRescueClause = {
	var exceptionClasses:Array<String>;
	var binding:Null<String>;
	var body:Array<RubyStatement>;
}
