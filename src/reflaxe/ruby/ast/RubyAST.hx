package reflaxe.ruby.ast;

typedef RubyFile = {
	var modulePath:Array<String>;
	var statements:Array<RubyStatement>;
}

enum RubyStatement {
	RubyComment(text:String);
	RubyRawStatement(code:String);
	RubyModuleDecl(name:String, body:Array<RubyStatement>);
	RubyClassDecl(name:String, body:Array<RubyStatement>);
	RubyMethodDecl(name:String, args:Array<String>, body:Array<RubyStatement>);
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
	RubyLocal(name:String);
	RubyArray(values:Array<RubyExpr>);
	RubyHash(fields:Array<RubyHashField>);
	RubyBinary(op:String, left:RubyExpr, right:RubyExpr);
	RubyUnary(op:String, expr:RubyExpr);
	RubyLambda(args:Array<String>, body:String);
	RubyCall(?receiver:RubyExpr, name:String, args:Array<RubyExpr>);
	RubyRawExpr(code:String);
}

typedef RubyHashField = {
	var key:String;
	var value:RubyExpr;
}
