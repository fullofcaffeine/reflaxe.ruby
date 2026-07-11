package reflaxe.ruby.ast;

import reflaxe.ruby.ast.RubyAST.RubyFile;
import reflaxe.ruby.ast.RubyAST.RubyBlock;
import reflaxe.ruby.ast.RubyAST.RubyCallArgument;
import reflaxe.ruby.ast.RubyAST.RubyExpr;
import reflaxe.ruby.ast.RubyAST.RubyMethodParameter;
import reflaxe.ruby.ast.RubyAST.RubyStatement;

class RubyASTPrinter {
	public static function printFile(file:RubyFile):String {
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
				for (line in splitCodeLines(printExpr(expr))) {
					lines.push(indent + line);
				}
			case RubyAssign(target, value):
				var valueLines = splitCodeLines(printExpr(value));
				if (valueLines.length == 0) {
					lines.push(indent + printExpr(target) + " = ");
				} else {
					lines.push(indent + printExpr(target) + " = " + valueLines[0]);
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
					var valueLines = splitCodeLines(printExpr(value));
					lines.push(indent + "return " + valueLines[0]);
					for (line in valueLines.slice(1)) {
						lines.push(indent + line);
					}
				}
			case RubyIfStmt(cond, thenBody, elseBody):
				lines.push(indent + "if " + printExpr(cond));
				writeBody(lines, thenBody, indentLevel + 1);
				if (elseBody != null && elseBody.length > 0) {
					lines.push(indent + "else");
					writeBody(lines, elseBody, indentLevel + 1);
				}
				lines.push(indent + "end");
			case RubyWhileStmt(cond, body):
				lines.push(indent + "while " + printExpr(cond));
				writeBody(lines, body, indentLevel + 1);
				lines.push(indent + "end");
		}
	}

	public static function printExpr(expr:RubyExpr):String {
		return switch (expr) {
			case RubyNil: "nil";
			case RubyBool(value): value ? "true" : "false";
			case RubyInt(value): value;
			case RubyFloat(value): normalizeFloatLiteral(value);
			case RubyString(value): quoteRubyString(value);
			case RubyLocal(name): name;
			case RubyArray(values): "[" + [for (value in values) printExpr(value)].join(", ") + "]";
			case RubyHash(fields): "{" + [
					for (field in fields)
						quoteRubyString(field.key) + " => " + printExpr(field.value)
				].join(", ") + "}";
			case RubyBinary(op, left, right): "(" + printExpr(left) + " " + op + " " + printExpr(right) + ")";
			case RubyUnary(op, value): "(" + op + printExpr(value) + ")";
			case RubyLambda(args, body): printLambda(args, body);
			case RubyCall(receiver, name, args):
				var printedArgs = args == null ? "" : [for (arg in args) printExpr(arg)].join(", ");
				receiver == null ? name + "(" + printedArgs + ")" : printExpr(receiver)
				+ "."
				+ name
				+ "("
				+ printedArgs
				+ ")";
			case RubyCallableCall(receiver, name, args, block):
				printCallableCall(receiver, name, args, block);
			case RubyYield(args):
				"yield(" + (args == null ? "" : [for (arg in args) printExpr(arg)].join(", ")) + ")";
			case RubyRawExpr(code): code;
		}
	}

	static function printMethodParameter(parameter:RubyMethodParameter):String {
		return switch (parameter) {
			case RubyRequiredParameter(name): name;
			case RubyOptionalParameter(name, defaultValue): name + " = " + printExpr(defaultValue);
			case RubyRestParameter(name): "*" + name;
			case RubyRequiredKeywordParameter(name): name + ":";
			case RubyOptionalKeywordParameter(name, defaultValue): name + ": " + printExpr(defaultValue);
			case RubyKeywordRestParameter(name): "**" + name;
			case RubyBlockParameter(name): "&" + name;
		}
	}

	static function printCallArgument(argument:RubyCallArgument):String {
		return switch (argument) {
			case RubyPositionalArgument(value): printExpr(value);
			case RubySplatArgument(value): "*" + printExpr(value);
			case RubyKeywordArgument(name, value): name + ": " + printExpr(value);
			case RubyKeywordSplatArgument(value): "**" + printExpr(value);
			case RubyBlockPassArgument(value): "&" + printExpr(value);
		}
	}

	static function printCallableCall(receiver:Null<RubyExpr>, name:String, args:Array<RubyCallArgument>, block:Null<RubyBlock>):String {
		var printedArgs = args == null ? "" : [for (arg in args) printCallArgument(arg)].join(", ");
		var callable = receiver == null ? name : printExpr(receiver) + "." + name;
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
				case RubyExprStatement(value):
					var printedBody = printExpr(value);
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
				case RubyExprStatement(expr):
					return "->(" + printedArgs + ") { " + printExpr(expr) + " }";
				case _:
			}
		}
		var lines = ["->(" + printedArgs + ") do"];
		writeBody(lines, body, 1);
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
		return "\"" + escaped + "\"";
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
