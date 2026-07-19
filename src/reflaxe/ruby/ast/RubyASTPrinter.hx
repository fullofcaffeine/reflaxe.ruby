package reflaxe.ruby.ast;

import reflaxe.ruby.ast.RubyAST.RubyFile;
import reflaxe.ruby.ast.RubyAST.RubyBlock;
import reflaxe.ruby.ast.RubyAST.RubyCaseBranch;
import reflaxe.ruby.ast.RubyAST.RubyCallArgument;
import reflaxe.ruby.ast.RubyAST.RubyExpr;
import reflaxe.ruby.ast.RubyAST.RubyMethodParameter;
import reflaxe.ruby.ast.RubyAST.RubyRescueClause;
import reflaxe.ruby.ast.RubyAST.RubyStatement;

class RubyASTPrinter {
	static final RUBY_BINARY_OPERATOR_METHODS = [
		"<=>", "==", "===", "!=", "=~", "!~", "+", "-", "*", "/", "%", "**", "<<", ">>", "&", "|", "^", "<", "<=", ">", ">="
	];

	public static function printFile(file:RubyFile):String {
		RubyASTValidator.validateFile(file);
		var lines = new Array<String>();
		for (statement in file.statements) {
			writeStatement(lines, statement, 0);
		}
		if (lines.length == 0 || lines[lines.length - 1] != "") {
			lines.push("");
		}
		return normalizeLineEndings(lines.join("\n"));
	}

	static function writeStatement(lines:Array<String>, statement:RubyStatement, indentLevel:Int):Void {
		var indent = indentation(indentLevel);
		switch (statement) {
			case RubyNoop:
				return;
			case RubyComment(text):
				lines.push(indent + "# " + text);
			case RubyRawStatement(code):
				for (line in splitCodeLines(code)) {
					lines.push(indent + line);
				}
			case RubyStatementSequence(body):
				for (child in body) {
					writeStatement(lines, child, indentLevel);
				}
			case RubyModuleDecl(name, body):
				lines.push(indent + "module " + name);
				writeBody(lines, body, indentLevel + 1);
				lines.push(indent + "end");
			case RubyClassDecl(name, body):
				lines.push(indent + "class " + name);
				writeBody(lines, body, indentLevel + 1);
				lines.push(indent + "end");
			case RubyClassDeclWithSuper(name, superclass, body):
				lines.push(indent + "class " + name + " < " + superclass);
				writeBody(lines, body, indentLevel + 1);
				lines.push(indent + "end");
			case RubyMethodDecl(name, args, body):
				var printedArgs = args == null ? "" : [for (arg in args) printMethodParameter(arg)].join(", ");
				lines.push(indent + "def " + name + "(" + printedArgs + ")");
				writeBody(lines, body, indentLevel + 1);
				lines.push(indent + "end");
			case RubyExprStatement(expr):
				for (line in splitCodeLines(printStatementExpr(expr))) {
					lines.push(indent + line);
				}
			case RubyAssign(target, value):
				var valueLines = splitCodeLines(renderExpr(value));
				if (valueLines.length == 0) {
					lines.push(indent + renderExpr(target) + " = ");
				} else {
					lines.push(indent + renderExpr(target) + " = " + valueLines[0]);
					for (line in valueLines.slice(1)) {
						lines.push(indent + line);
					}
				}
			case RubyReturn(value):
				if (value == null) {
					lines.push(indent + "return");
				} else {
					// Expressions such as a call with a `do ... end` block span lines.
					// Prefix every rendered line with the enclosing statement indent so
					// returned blocks remain nested like handwritten Ruby.
					var valueLines = splitCodeLines(renderExpr(value));
					lines.push(indent + "return " + valueLines[0]);
					for (line in valueLines.slice(1)) {
						lines.push(indent + line);
					}
				}
			case RubyIfStmt(cond, thenBody, elseBody):
				lines.push(indent + "if " + renderExpr(cond));
				writeBody(lines, thenBody, indentLevel + 1);
				if (elseBody != null && elseBody.length > 0) {
					lines.push(indent + "else");
					writeBody(lines, elseBody, indentLevel + 1);
				}
				lines.push(indent + "end");
			case RubyWhileStmt(cond, body):
				lines.push(indent + "while " + renderExpr(cond));
				writeBody(lines, body, indentLevel + 1);
				lines.push(indent + "end");
		}
	}

	public static function printExpr(expr:RubyExpr):String {
		RubyASTValidator.validateExpr(expr);
		return renderExpr(expr);
	}

	static function renderExpr(expr:RubyExpr):String {
		return switch (expr) {
			case RubyNil: "nil";
			case RubyBool(value): value ? "true" : "false";
			case RubyInt(value): value;
			case RubyFloat(value): normalizeFloatLiteral(value);
			case RubyString(value): quoteRubyString(value);
			case RubySymbol(value): rubySymbol(value);
			case RubyLocal(name): name;
			case RubyArray(values): "[" + [for (value in values) renderExpr(value)].join(", ") + "]";
			case RubyHash(fields): "{" + [
					for (field in fields)
						quoteRubyString(field.key) + " => " + renderExpr(field.value)
				].join(", ") + "}";
			case RubySymbolHash(fields): "{" + [
					for (field in fields)
						isSimpleRubyLabel(field.key) ? field.key + ": " + renderExpr(field.value) : rubySymbol(field.key) + " => " + renderExpr(field.value)
				].join(", ") + "}";
			case RubyIndex(receiver, index): renderExpr(receiver) + "[" + renderExpr(index) + "]";
			case RubyMember(receiver, name): renderExpr(receiver) + "." + name;
			case RubyBinary(op, left, right): "(" + renderExpr(left) + " " + op + " " + renderExpr(right) + ")";
			case RubyUnary(op, value): "(" + op + renderExpr(value) + ")";
			case RubyConditional(cond, thenExpr, elseExpr):
				"("
				+ renderExpr(cond)
				+ " ? "
				+ renderExpr(thenExpr)
				+ " : "
				+ renderExpr(elseExpr)
				+ ")";
			case RubyBegin(body): printBegin(body);
			case RubyBeginRescue(body, rescues): printBeginRescue(body, rescues);
			case RubyLambda(args, body): printLambda(args, body);
			case RubyCallableLambda(args, body): printCallableLambda(args, body);
			case RubyCall(receiver, name, args):
				var printedArgs = args == null ? "" : [for (arg in args) renderExpr(arg)].join(", ");
				if (receiver != null && isRubyBinaryOperatorName(name) && args != null && args.length == 1) {
					printBinaryOperatorCall(receiver, name, args[0]);
				} else if (receiver != null && isRubyWriterName(name) && args != null && args.length == 1) {
					"(" + printWriterAssignment(receiver, name, args[0]) + ")";
				} else {
					receiver == null ? name + "(" + printedArgs + ")" : renderExpr(receiver) + "." + name + "(" + printedArgs + ")";
				}
			case RubyCallableCall(receiver, name, args, block):
				printCallableCall(receiver, name, args, block);
			case RubyYield(args): args == null || args.length == 0 ? "yield" : "yield(" + [for (arg in args) renderExpr(arg)].join(", ") + ")";
			case RubyCase(scrutinee, branches, defaultBody): printCase(scrutinee, branches, defaultBody);
			case RubyRuntimeCall(use, args):
				RubyRuntimePlan.rubyReceiver(use)
				+ "."
				+ use.helper.rubyName()
				+ "("
				+ (args == null ? "" : [for (arg in args) renderExpr(arg)].join(", "))
				+ ")";
			case RubyRaise(exception): "(" + printRaise(exception) + ")";
			case RubyBreak: "(break)";
			case RubyNext: "(next)";
			case RubyRawExpr(code): code;
		}
	}

	static function printMethodParameter(parameter:RubyMethodParameter):String {
		return switch (parameter) {
			case RubyRequiredParameter(name): name;
			case RubyOptionalParameter(name, defaultValue): name + " = " + renderExpr(defaultValue);
			case RubyRestParameter(name): "*" + name;
			case RubyRequiredKeywordParameter(name): name + ":";
			case RubyOptionalKeywordParameter(name, defaultValue): name + ": " + renderExpr(defaultValue);
			case RubyKeywordRestParameter(name): "**" + name;
			case RubyBlockParameter(name): "&" + name;
		}
	}

	static function printStatementExpr(expr:RubyExpr):String {
		return switch (expr) {
			case RubyRaise(exception):
				printRaise(exception);
			case RubyBreak:
				"break";
			case RubyNext:
				"next";
			case RubyCall(receiver, name, args) if (receiver != null && isRubyWriterName(name) && args != null && args.length == 1):
				printWriterAssignment(receiver, name, args[0]);
			case _: renderExpr(expr);
		}
	}

	static function printWriterAssignment(receiver:RubyExpr, name:String, value:RubyExpr):String {
		return renderExpr(receiver) + "." + name.substr(0, name.length - 1) + " = " + renderExpr(value);
	}

	static function printCallArgument(argument:RubyCallArgument):String {
		return switch (argument) {
			case RubyPositionalArgument(value): renderExpr(value);
			case RubySplatArgument(value): "*" + renderExpr(value);
			case RubyKeywordArgument(name, value): name + ": " + renderExpr(value);
			case RubyKeywordSplatArgument(value): "**" + renderExpr(value);
			case RubyBlockPassArgument(value): "&" + renderExpr(value);
		}
	}

	static function printCallableCall(receiver:Null<RubyExpr>, name:String, args:Array<RubyCallArgument>, block:Null<RubyBlock>):String {
		if (receiver != null && block == null && isRubyBinaryOperatorName(name) && args != null && args.length == 1) {
			switch (args[0]) {
				case RubyPositionalArgument(value):
					return printBinaryOperatorCall(receiver, name, value);
				case _:
			}
		}
		var printedArgs = args == null ? "" : [for (arg in args) printCallArgument(arg)].join(", ");
		var callable = receiver == null ? name : renderExpr(receiver) + "." + name;
		// Rubyists conventionally omit empty parentheses when a native block is
		// attached (`items.each { ... }`). Keep parentheses for ordinary calls and
		// calls with arguments, where they make precedence explicit.
		var call = block != null && printedArgs == "" ? callable : callable + "(" + printedArgs + ")";
		if (block == null) {
			return call;
		}
		var blockArgs = block.args == null || block.args.length == 0 ? "" : " |" + block.args.join(", ") + "|";
		if (block.body != null && block.body.length == 1) {
			switch (block.body[0]) {
				case RubyExprStatement(RubyRaise(_) | RubyBreak | RubyNext):
					// Keep control transfer visually explicit and preserve the
					// statement-shaped block used before structural lowering.
					null;
				case RubyExprStatement(value):
					var printedBody = renderExpr(value);
					if (printedBody.indexOf("\n") == -1) {
						return call + " {" + blockArgs + " " + printedBody + " }";
					}
				case _:
			}
		}
		var lines = [call + " do" + blockArgs];
		writeBody(lines, block.body, 1);
		lines.push("end");
		return lines.join("\n");
	}

	/** Prints validated native binary methods in normal Ruby infix form. **/
	static function printBinaryOperatorCall(receiver:RubyExpr, name:String, argument:RubyExpr):String {
		return "(" + renderExpr(receiver) + " " + name + " " + renderExpr(argument) + ")";
	}

	static function isRubyBinaryOperatorName(name:String):Bool {
		return RUBY_BINARY_OPERATOR_METHODS.indexOf(name) != -1;
	}

	static function writeBody(lines:Array<String>, body:Array<RubyStatement>, indentLevel:Int):Void {
		if (body == null || body.length == 0) {
			lines.push(indentation(indentLevel) + "# No Ruby members emitted.");
			return;
		}
		for (statement in body) {
			writeStatement(lines, statement, indentLevel);
		}
	}

	static function printLambda(args:Array<String>, body:Array<RubyStatement>):String {
		var printedArgs = args == null ? "" : args.join(", ");
		if (body != null && body.length == 1) {
			switch (body[0]) {
				case RubyExprStatement(RubyRaise(_) | RubyBreak | RubyNext):
					null;
				case RubyExprStatement(expr):
					return "->(" + printedArgs + ") { " + renderExpr(expr) + " }";
				case _:
			}
		}
		var lines = ["->(" + printedArgs + ") do"];
		writeBody(lines, body, 1);
		lines.push("end");
		return lines.join("\n");
	}

	static function printCallableLambda(args:Array<RubyMethodParameter>, body:Array<RubyStatement>):String {
		var printedArgs = args == null ? "" : [for (arg in args) printMethodParameter(arg)].join(", ");
		if (body != null && body.length == 1) {
			switch (body[0]) {
				case RubyExprStatement(RubyRaise(_) | RubyBreak | RubyNext):
					null;
				case RubyExprStatement(expr):
					return "->(" + printedArgs + ") { " + renderExpr(expr) + " }";
				case _:
			}
		}
		var lines = ["->(" + printedArgs + ") do"];
		writeBody(lines, body, 1);
		lines.push("end");
		return lines.join("\n");
	}

	static function printBegin(body:Array<RubyStatement>):String {
		var lines = ["begin"];
		writeBody(lines, body, 1);
		lines.push("end");
		return lines.join("\n");
	}

	static function printBeginRescue(body:Array<RubyStatement>, rescues:Array<RubyRescueClause>):String {
		var lines = ["begin"];
		writeBody(lines, body, 1);
		for (rescue in rescues) {
			var header = "rescue " + rescue.exceptionClasses.join(", ");
			if (rescue.binding != null) {
				header += " => " + rescue.binding;
			}
			lines.push(header);
			writeBody(lines, rescue.body, 1);
		}
		lines.push("end");
		return lines.join("\n");
	}

	static function printRaise(exception:Null<RubyExpr>):String {
		return exception == null ? "raise" : "raise " + renderExpr(exception);
	}

	static function printCase(scrutinee:RubyExpr, branches:Array<RubyCaseBranch>, defaultBody:Null<Array<RubyStatement>>):String {
		var lines = ["case " + renderExpr(scrutinee)];
		for (branch in branches) {
			lines.push("when " + [for (value in branch.values) renderExpr(value)].join(", "));
			writeBody(lines, branch.body, 1);
		}
		if (defaultBody != null) {
			lines.push("else");
			writeBody(lines, defaultBody, 1);
		}
		lines.push("end");
		return lines.join("\n");
	}

	static function indentation(level:Int):String {
		var out = "";
		for (_ in 0...level) {
			out += "  ";
		}
		return out;
	}

	static function quoteRubyString(value:String):String {
		var escaped = value == null ? "" : value;
		escaped = StringTools.replace(escaped, "\\", "\\\\");
		escaped = StringTools.replace(escaped, "\"", "\\\"");
		escaped = StringTools.replace(escaped, "\n", "\\n");
		escaped = StringTools.replace(escaped, "\r", "\\r");
		escaped = StringTools.replace(escaped, "\t", "\\t");
		// Ruby interpolates all three forms inside double-quoted strings. Escape
		// only those prefixes so ordinary `#` characters remain idiomatic.
		escaped = StringTools.replace(escaped, "#{", "\\#{");
		escaped = StringTools.replace(escaped, "#@", "\\#@");
		escaped = StringTools.replace(escaped, "#" + "$", "\\#" + "$");
		return "\"" + escaped + "\"";
	}

	static function rubySymbol(value:String):String {
		return isSimpleRubySymbol(value) ? ":" + value : ":" + quoteRubyString(value);
	}

	static function isSimpleRubyLabel(value:String):Bool {
		return value != null && ~/^[A-Za-z_][A-Za-z0-9_]*$/.match(value);
	}

	static function isSimpleRubySymbol(value:String):Bool {
		if (value == null || value.length == 0) {
			return false;
		}
		var first = value.charCodeAt(0);
		if (!isRubyIdentStart(first)) {
			return false;
		}
		var limit = value.length;
		var last = value.charAt(value.length - 1);
		if (last == "!" || last == "?" || last == "=") {
			limit--;
		}
		for (i in 1...limit) {
			if (!isRubyIdentPart(value.charCodeAt(i))) {
				return false;
			}
		}
		return true;
	}

	static function isRubyIdentStart(code:Int):Bool {
		return code == 95 || (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
	}

	static function isRubyIdentPart(code:Int):Bool {
		return isRubyIdentStart(code) || (code >= 48 && code <= 57);
	}

	static function isRubyWriterName(value:String):Bool {
		return value != null && ~/^[A-Za-z_][A-Za-z0-9_]*=$/.match(value);
	}

	static function normalizeFloatLiteral(value:String):String {
		if (value == null || value.length == 0) {
			return "0.0";
		}
		return StringTools.endsWith(value, ".") ? value + "0" : value;
	}

	static function splitCodeLines(code:String):Array<String> {
		return normalizeLineEndings(code).split("\n");
	}

	static function normalizeLineEndings(code:String):String {
		return StringTools.replace(code == null ? "" : code, "\r\n", "\n").split("\r").join("\n");
	}
}
