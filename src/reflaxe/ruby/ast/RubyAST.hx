package reflaxe.ruby.ast;

typedef RubyFile = {
	var modulePath:Array<String>;
	var statements:Array<RubyStatement>;
}

enum RubyStatement {
	RubyNoop;
	RubyComment(text:String);
	RubyRawStatement(code:String);
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
	RubyBinary(op:String, left:RubyExpr, right:RubyExpr);
	RubyUnary(op:String, expr:RubyExpr);
	RubyConditional(cond:RubyExpr, thenExpr:RubyExpr, elseExpr:RubyExpr);
	RubyBegin(body:Array<RubyStatement>);
	RubyLambda(args:Array<String>, body:Array<RubyStatement>);
	RubyCall(?receiver:RubyExpr, name:String, args:Array<RubyExpr>);
	RubyCallableCall(?receiver:RubyExpr, name:String, args:Array<RubyCallArgument>, ?block:RubyBlock);
	RubyYield(args:Array<RubyExpr>);
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
