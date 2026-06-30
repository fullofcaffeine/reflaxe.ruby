package reflaxe.ruby.ast;

import reflaxe.ruby.ast.RubyAST.RubyFile;
import reflaxe.ruby.ast.RubyAST.RubyExpr;
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
				lines.push(indent + "def " + name + "(" + (args == null ? "" : args.join(", ")) + ")");
				writeBody(lines, body, indentLevel + 1);
				lines.push(indent + "end");
			case RubyExprStatement(expr):
				for (line in splitCodeLines(printExpr(expr))) {
					lines.push(indent + line);
				}
			case RubyAssign(target, value):
				lines.push(indent + printExpr(target) + " = " + printExpr(value));
			case RubyReturn(value):
				lines.push(indent + (value == null ? "return" : "return " + printExpr(value)));
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
			case RubyFloat(value): value;
			case RubyString(value): quoteRubyString(value);
			case RubyLocal(name): name;
			case RubyArray(values): "[" + [for (value in values) printExpr(value)].join(", ") + "]";
			case RubyHash(fields): "{" + [
					for (field in fields)
						quoteRubyString(field.key) + " => " + printExpr(field.value)
				].join(", ") + "}";
			case RubyBinary(op, left, right): "(" + printExpr(left) + " " + op + " " + printExpr(right) + ")";
			case RubyUnary(op, value): "(" + op + printExpr(value) + ")";
			case RubyLambda(args, body): "->(" + (args == null ? "" : args.join(", ")) + ") { " + body + " }";
			case RubyCall(receiver, name, args):
				var printedArgs = args == null ? "" : [for (arg in args) printExpr(arg)].join(", ");
				receiver == null ? name + "(" + printedArgs + ")" : printExpr(receiver)
				+ "."
				+ name
				+ "("
				+ printedArgs
				+ ")";
			case RubyRawExpr(code): code;
		}
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

	static function splitCodeLines(code:String):Array<String> {
		return normalizeLineEndings(code).split("\n");
	}

	static function normalizeLineEndings(code:String):String {
		return StringTools.replace(code == null ? "" : code, "\r\n", "\n").split("\r").join("\n");
	}
}
