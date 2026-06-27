package reflaxe.ruby.macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

/**
	Rewrites Haxe inline markup (`return <div>...</div>`) in Rails template
	classes into the typed `rails.action_view.HtmlNode` AST consumed by
	`@:railsTemplateAst(...)`.

	This mirrors the haxe.elixir.codex HXX/HEEx architecture: app code gets
	xml/html-like Haxe syntax with `${...}` splices, while the backend receives a
	typed compile-time AST and emits normal Rails ERB.
**/
class RailsInlineMarkup {
	public static function enable():Void {
		if (Context.defined("rails_hxx_no_inline_markup")) {
			return;
		}
		Compiler.addGlobalMetadata("", "@:build(reflaxe.ruby.macros.RailsInlineMarkup.build())", true, true, false);
	}

	public static macro function build():Array<Field> {
		var fields = Context.getBuildFields();
		if (!shouldProcessLocalType()) {
			return fields;
		}
		for (field in fields) {
			rewriteField(field);
		}
		return fields;
	}

	static function shouldProcessLocalType():Bool {
		if (Context.defined("rails_hxx_no_inline_markup")) {
			return false;
		}
		var localClassRef = Context.getLocalClass();
		if (localClassRef == null) {
			return false;
		}
		var cls = localClassRef.get();
		if (cls == null || cls.meta == null) {
			return false;
		}
		if (cls.meta.has(":rails_hxx_no_inline_markup") || cls.meta.has("rails_hxx_no_inline_markup")) {
			return false;
		}
		return cls.meta.has(":railsTemplate")
			|| cls.meta.has("railsTemplate")
			|| cls.meta.has(":rails_hxx_inline_markup")
			|| cls.meta.has("rails_hxx_inline_markup");
	}

	static function rewriteField(field:Field):Void {
		if (field == null) {
			return;
		}
		switch (field.kind) {
			case FFun(fn):
				if (fn != null && fn.expr != null) {
					fn.expr = rewriteExpr(fn.expr);
				}
			case FVar(t, e):
				if (e != null) {
					field.kind = FVar(t, rewriteExpr(e));
				}
			case FProp(get, set, t, e):
				if (e != null) {
					field.kind = FProp(get, set, t, rewriteExpr(e));
				}
		}
	}

	static function rewriteExpr(expr:Expr):Expr {
		if (expr == null) {
			return null;
		}
		inline function mk(next:ExprDef):Expr {
			return {expr: next, pos: expr.pos};
		}
		function mapArray<T>(arr:Array<T>, mapFn:(T) -> T):Array<T> {
			if (arr == null) {
				return null;
			}
			var changed = false;
			var out:Array<T> = null;
			for (i in 0...arr.length) {
				var v = arr[i];
				var nv = mapFn(v);
				if (!changed && nv != v) {
					changed = true;
					out = arr.copy();
				}
				if (changed) {
					out[i] = nv;
				}
			}
			return changed ? out : arr;
		}
		return switch (expr.expr) {
			case EMeta(meta, inner) if (meta != null && meta.name == ":markup"):
				var rewrittenInner = rewriteExpr(inner);
				switch (rewrittenInner.expr) {
					case EConst(CString(payload, _)):
						var nodeExpr = RailsMarkupParser.parseRoot(payload, rewrittenInner.pos);
						rewriteExpr(nodeExpr);
					default:
						Context.error("Rails HHX inline markup expected a constant parser payload.", rewrittenInner.pos);
				}
			case EMeta(meta, inner):
				var nextInner = rewriteExpr(inner);
				if (nextInner == inner) expr else mk(EMeta(meta, nextInner));
			case EBlock(exprs):
				var next = mapArray(exprs, rewriteExpr);
				if (next == exprs) expr else mk(EBlock(next));
			case EReturn(value):
				var nextValue = value == null ? null : rewriteExpr(value);
				if (nextValue == value) expr else mk(EReturn(nextValue));
			case ECall(fn, args):
				var nextFn = rewriteExpr(fn);
				var nextArgs = mapArray(args, rewriteExpr);
				if (nextFn == fn && nextArgs == args) expr else mk(ECall(nextFn, nextArgs));
			case EArrayDecl(values):
				var nextValues = mapArray(values, rewriteExpr);
				if (nextValues == values) expr else mk(EArrayDecl(nextValues));
			case EObjectDecl(fields):
				var nextFields = mapArray(fields, function(f) {
					var nextExpr = rewriteExpr(f.expr);
					return nextExpr == f.expr ? f : {field: f.field, expr: nextExpr, quotes: f.quotes};
				});
				if (nextFields == fields) expr else mk(EObjectDecl(nextFields));
			case EParenthesis(inner):
				var nextInner2 = rewriteExpr(inner);
				if (nextInner2 == inner) expr else mk(EParenthesis(nextInner2));
			case EBinop(op, left, right):
				var nextLeft = rewriteExpr(left);
				var nextRight = rewriteExpr(right);
				if (nextLeft == left && nextRight == right) expr else mk(EBinop(op, nextLeft, nextRight));
			case EUnop(op, postFix, inner):
				var nextInner3 = rewriteExpr(inner);
				if (nextInner3 == inner) expr else mk(EUnop(op, postFix, nextInner3));
			case EIf(cond, thenExpr, elseExpr):
				var nextCond = rewriteExpr(cond);
				var nextThen = rewriteExpr(thenExpr);
				var nextElse = elseExpr == null ? null : rewriteExpr(elseExpr);
				if (nextCond == cond && nextThen == thenExpr && nextElse == elseExpr) expr else mk(EIf(nextCond, nextThen, nextElse));
			case EFor(it, body):
				var nextIt = rewriteExpr(it);
				var nextBody = rewriteExpr(body);
				if (nextIt == it && nextBody == body) expr else mk(EFor(nextIt, nextBody));
			case EWhile(cond, body, normalWhile):
				var nextCond2 = rewriteExpr(cond);
				var nextBody2 = rewriteExpr(body);
				if (nextCond2 == cond && nextBody2 == body) expr else mk(EWhile(nextCond2, nextBody2, normalWhile));
			case ESwitch(subject, cases, defaultExpr):
				var nextSubject = rewriteExpr(subject);
				var nextCases = mapArray(cases, function(c) {
					var nextValues = mapArray(c.values, rewriteExpr);
					var nextGuard = c.guard == null ? null : rewriteExpr(c.guard);
					var nextExpr = c.expr == null ? null : rewriteExpr(c.expr);
					return nextValues == c.values && nextGuard == c.guard && nextExpr == c.expr ? c : {
						values: nextValues,
						guard: nextGuard,
						expr: nextExpr
					};
				});
				var nextDefault = defaultExpr == null ? null : rewriteExpr(defaultExpr);
				if (nextSubject == subject && nextCases == cases && nextDefault == defaultExpr) expr else mk(ESwitch(nextSubject, nextCases, nextDefault));
			case ETry(body, catches):
				var nextBody3 = rewriteExpr(body);
				var nextCatches = mapArray(catches, function(c) {
					var nextExpr = rewriteExpr(c.expr);
					return nextExpr == c.expr ? c : {name: c.name, type: c.type, expr: nextExpr};
				});
				if (nextBody3 == body && nextCatches == catches) expr else mk(ETry(nextBody3, nextCatches));
			case EFunction(kind, fn):
				if (fn == null || fn.expr == null) {
					expr;
				} else {
					var nextBody4 = rewriteExpr(fn.expr);
					if (nextBody4 == fn.expr) {
						expr;
					} else {
						var nextFn:Function = {
							args: fn.args,
							ret: fn.ret,
							expr: nextBody4,
							params: fn.params
						};
						mk(EFunction(kind, nextFn));
					}
				}
			case EVars(vars):
				var nextVars = mapArray(vars, function(v) {
					var nextExpr = v.expr == null ? null : rewriteExpr(v.expr);
					return nextExpr == v.expr ? v : {
						name: v.name,
						type: v.type,
						expr: nextExpr,
						isFinal: v.isFinal,
						meta: v.meta
					};
				});
				if (nextVars == vars) expr else mk(EVars(nextVars));
			default:
				expr;
		}
	}
}

private enum RailsAttrKind {
	Static(value:String);
	Bool;
	ExprValue(value:Expr);
}

private typedef RailsParsedAttr = {
	var name:String;
	var kind:RailsAttrKind;
	var expr:Expr;
	var pos:Position;
}

private class RailsMarkupParser {
	public static function parseRoot(template:String, templatePos:Position):Expr {
		var parser = new RailsMarkupParser(template, templatePos);
		var nodes = parser.parseNodesUntil(null);
		if (!parser.eof()) {
			parser.failHere("Unexpected trailing input in Rails HHX template");
		}
		return nodes.length == 1 ? nodes[0] : parser.mkFragment(nodes, templatePos);
	}

	final src:String;
	final basePos:Position;
	var i:Int = 0;

	function new(src:String, basePos:Position) {
		this.src = src == null ? "" : src;
		this.basePos = basePos;
	}

	inline function eof():Bool {
		return i >= src.length;
	}

	inline function ch(at:Int):String {
		return src.charAt(at);
	}

	inline function startsWith(s:String):Bool {
		return s != null && i + s.length <= src.length && src.substr(i, s.length) == s;
	}

	function skipWs():Void {
		while (!eof()) {
			var c = ch(i);
			if (c == " " || c == "\t" || c == "\n" || c == "\r") {
				i++;
			} else {
				break;
			}
		}
	}

	function makeSubPos(startOffset:Int, endOffset:Int):Position {
		var info = Context.getPosInfos(basePos);
		var min = info.min + (startOffset < 0 ? 0 : startOffset);
		var max = info.min + (endOffset < startOffset ? startOffset : endOffset);
		if (max > info.max) {
			max = info.max;
		}
		if (min > info.max) {
			min = info.max;
		}
		return Context.makePosition({file: info.file, min: min, max: max});
	}

	public function failHere(msg:String):Void {
		Context.error(msg, makeSubPos(i, i + 1));
	}

	function expect(s:String, msg:String):Void {
		if (!startsWith(s)) {
			failHere(msg);
		}
		i += s.length;
	}

	function readName():String {
		skipWs();
		var start = i;
		while (!eof()) {
			var c = ch(i);
			var ok = (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || (c >= "0" && c <= "9") || c == "_" || c == "-" || c == ":" || c == ".";
			if (!ok) {
				break;
			}
			i++;
		}
		if (i == start) {
			failHere("Expected tag or attribute name");
		}
		return src.substr(start, i - start);
	}

	function readCurlyContent():{text:String, start:Int, end:Int} {
		var start = i;
		var depth = 1;
		var inSingle = false;
		var inDouble = false;
		var escaped = false;
		while (!eof()) {
			var c = ch(i);
			if (inSingle || inDouble) {
				if (!escaped && c == "\\") {
					escaped = true;
					i++;
					continue;
				}
				if (!escaped && inSingle && c == "'") {
					inSingle = false;
				} else if (!escaped && inDouble && c == "\"") {
					inDouble = false;
				}
				escaped = false;
				i++;
				continue;
			}
			if (c == "'") {
				inSingle = true;
				i++;
				continue;
			}
			if (c == "\"") {
				inDouble = true;
				i++;
				continue;
			}
			if (c == "{") {
				depth++;
				i++;
				continue;
			}
			if (c == "}") {
				depth--;
				if (depth == 0) {
					var end = i;
					i++;
					return {text: src.substr(start, end - start), start: start, end: end + 1};
				}
				i++;
				continue;
			}
			i++;
		}
		failHere("Missing closing '}'");
		return {text: "", start: start, end: start};
	}

	function parseExprInBraces():Expr {
		skipWs();
		var exprStart = i;
		if (startsWith("${")) {
			i += 2;
		} else if (startsWith("{")) {
			i += 1;
		} else {
			failHere("Expected ${...} expression");
		}
		var balanced = readCurlyContent();
		var text = StringTools.trim(balanced.text);
		if (text.length == 0) {
			Context.error("Expected expression", makeSubPos(exprStart, balanced.end));
		}
		return Context.parseInlineString(text, makeSubPos(balanced.start, balanced.end));
	}

	function parseForHead():{binder:String, items:Expr, pos:Position} {
		var headStart = i;
		var head = parseExprInBraces();
		return switch (head.expr) {
			case EBinop(OpIn, left, right):
				switch (left.expr) {
					case EConst(CIdent(name)):
						{binder: name, items: right, pos: makeSubPos(headStart, i)};
					default:
						Context.error("Rails HHX <for>: binder must be an identifier, for example <for ${todo in todos}>", left.pos);
				}
			default:
				Context.error("Rails HHX <for>: expected `binder in iterable`, for example <for ${todo in todos}>", head.pos);
		}
	}

	function mkArray(exprs:Array<Expr>, pos:Position):Expr {
		return {expr: EArrayDecl(exprs), pos: pos};
	}

	function mkText(value:String, pos:Position):Expr {
		return macro @:pos(pos) rails.action_view.HtmlNode.Text($v{value});
	}

	function mkExprText(value:Expr, pos:Position):Expr {
		return macro @:pos(pos) rails.action_view.HtmlNode.ExprText($value);
	}

	public function mkFragment(children:Array<Expr>, pos:Position):Expr {
		return macro @:pos(pos) rails.action_view.HtmlNode.Fragment(${mkArray(children, pos)});
	}

	function mkElement(name:String, attrs:Array<Expr>, children:Array<Expr>, pos:Position):Expr {
		return macro @:pos(pos) rails.action_view.HtmlNode.Element($v{name}, ${mkArray(attrs, pos)}, ${mkArray(children, pos)});
	}

	function mkFor(items:Expr, binderName:String, body:Expr, pos:Position):Expr {
		var arg:FunctionArg = {
			name: binderName,
			type: null,
			opt: false,
			value: null,
			meta: null
		};
		var fn:Function = {
			args: [arg],
			ret: null,
			expr: {expr: EReturn(body), pos: pos},
			params: []
		};
		return macro @:pos(pos) rails.action_view.HtmlNode.For($items, ${
			{expr: EFunction(FArrow, fn), pos: pos}
		});
	}

	function mkIf(cond:Expr, thenNode:Expr, elseNode:Null<Expr>, pos:Position):Expr {
		return macro @:pos(pos) rails.action_view.HtmlNode.If($cond, $thenNode, ${elseNode == null ? (macro null) : elseNode});
	}

	function mkAttr(attr:RailsParsedAttr):Expr {
		return switch (attr.kind) {
			case Static(value):
				macro @:pos(attr.pos) rails.action_view.HtmlAttr.Static($v{attr.name}, $v{value});
			case Bool:
				macro @:pos(attr.pos) rails.action_view.HtmlAttr.Bool($v{attr.name});
			case ExprValue(value):
				macro @:pos(attr.pos) rails.action_view.HtmlAttr.Expr($v{attr.name}, $value);
		}
	}

	function staticAttr(name:String, value:String, pos:Position):RailsParsedAttr {
		return {
			name: name,
			kind: Static(value),
			expr: macro @:pos(pos) rails.action_view.HtmlAttr.Static($v{name}, $v{value}),
			pos: pos
		};
	}

	function parseTextNodesUntilTag():Array<Expr> {
		var out:Array<Expr> = [];
		var textStart = i;
		while (!eof()) {
			if (startsWith("<") || startsWith("${")) {
				break;
			}
			i++;
		}
		if (i > textStart) {
			out.push(mkText(src.substr(textStart, i - textStart), makeSubPos(textStart, i)));
		}
		while (startsWith("${")) {
			var exprStart = i;
			var expr = parseExprInBraces();
			out.push(mkExprText(expr, makeSubPos(exprStart, i)));
			var segStart = i;
			while (!eof()) {
				if (startsWith("<") || startsWith("${")) {
					break;
				}
				i++;
			}
			if (i > segStart) {
				out.push(mkText(src.substr(segStart, i - segStart), makeSubPos(segStart, i)));
			}
		}
		return out;
	}

	function parseNodesUntil(closing:Null<String>):Array<Expr> {
		var nodes:Array<Expr> = [];
		while (!eof()) {
			if (startsWith("<!--")) {
				var commentStart = i;
				var end = src.indexOf("-->", i + 4);
				if (end == -1) {
					Context.error("Unclosed HTML comment", makeSubPos(commentStart, src.length));
				}
				i = end + 3;
				continue;
			}
			if (startsWith("</")) {
				if (closing == null) {
					failHere("Unexpected closing tag");
				}
				var closeStart = i;
				i += 2;
				var name = readName();
				skipWs();
				expect(">", "Expected '>' after closing tag");
				if (name != closing) {
					Context.error('Mismatched closing tag: expected </' + closing + '> but found </' + name + '>', makeSubPos(closeStart, i));
				}
				return nodes;
			}
			if (startsWith("<")) {
				nodes.push(parseTagNode());
				continue;
			}
			var textNodes = parseTextNodesUntilTag();
			for (node in textNodes) {
				nodes.push(node);
			}
		}
		if (closing != null) {
			Context.error("Unclosed <" + closing + "> tag", makeSubPos(i, i));
		}
		return nodes;
	}

	function parseNodesUntilStop(shouldStop:() -> Bool):Array<Expr> {
		var nodes:Array<Expr> = [];
		while (!eof() && !shouldStop()) {
			if (startsWith("<!--")) {
				var commentStart = i;
				var end = src.indexOf("-->", i + 4);
				if (end == -1) {
					Context.error("Unclosed HTML comment", makeSubPos(commentStart, src.length));
				}
				i = end + 3;
				continue;
			}
			if (startsWith("</")) {
				break;
			}
			if (startsWith("<")) {
				nodes.push(parseTagNode());
				continue;
			}
			var textNodes = parseTextNodesUntilTag();
			for (node in textNodes) {
				nodes.push(node);
			}
		}
		return nodes;
	}

	function parseNodesUntilFragmentClose(start:Int):Array<Expr> {
		var nodes:Array<Expr> = [];
		while (!eof()) {
			if (startsWith("</>")) {
				i += 3;
				return nodes;
			}
			if (startsWith("<!--")) {
				var commentStart = i;
				var end = src.indexOf("-->", i + 4);
				if (end == -1) {
					Context.error("Unclosed HTML comment", makeSubPos(commentStart, src.length));
				}
				i = end + 3;
				continue;
			}
			if (startsWith("</")) {
				failHere("Unexpected closing tag");
			}
			if (startsWith("<")) {
				nodes.push(parseTagNode());
				continue;
			}
			var textNodes = parseTextNodesUntilTag();
			for (node in textNodes) {
				nodes.push(node);
			}
		}
		Context.error("Unclosed <> fragment", makeSubPos(start, i));
		return nodes;
	}

	function parseTagNode():Expr {
		var tagStart = i;
		expect("<", "Expected '<' to start a tag");
		if (startsWith(">")) {
			i++;
			return mkFragment(parseNodesUntilFragmentClose(tagStart), makeSubPos(tagStart, i));
		}
		var name = readName();
		if (name == "if") {
			skipWs();
			var cond = parseExprInBraces();
			skipWs();
			expect(">", "Expected '>' after <if ${...}>");
			var thenNodes = parseNodesUntilStop(() -> startsWith("<else>") || startsWith("</if>"));
			var elseNodes:Null<Array<Expr>> = null;
			if (startsWith("<else>")) {
				i += "<else>".length;
				elseNodes = parseNodesUntilStop(() -> startsWith("</if>"));
			}
			expect("</if>", "Expected </if> to close <if>");
			var thenNode = thenNodes.length == 1 ? thenNodes[0] : mkFragment(thenNodes, makeSubPos(tagStart, i));
			var elseNode = elseNodes == null ? null : (elseNodes.length == 1 ? elseNodes[0] : mkFragment(elseNodes, makeSubPos(tagStart, i)));
			return mkIf(cond, thenNode, elseNode, makeSubPos(tagStart, i));
		}
		if (name == "for") {
			skipWs();
			var head = parseForHead();
			skipWs();
			expect(">", "Expected '>' after <for ${...}>");
			var bodyNodes = parseNodesUntil("for");
			var body = bodyNodes.length == 1 ? bodyNodes[0] : mkFragment(bodyNodes, makeSubPos(tagStart, i));
			return mkFor(head.items, head.binder, body, makeSubPos(tagStart, i));
		}
		var attrs:Array<RailsParsedAttr> = [];
		var selfClosing = false;
		while (!eof()) {
			skipWs();
			if (startsWith("/>")) {
				selfClosing = true;
				i += 2;
				break;
			}
			if (startsWith(">")) {
				i++;
				break;
			}
			attrs.push(parseAttr());
		}
		var children:Array<Expr> = [];
		if (!selfClosing) {
			children = parseNodesUntil(name);
		}
		return lowerTag(name, attrs, children, makeSubPos(tagStart, i));
	}

	function parseAttr():RailsParsedAttr {
		var attrStart = i;
		var name = readName();
		skipWs();
		if (!startsWith("=")) {
			var pos = makeSubPos(attrStart, i);
			return {
				name: name,
				kind: Bool,
				expr: macro @:pos(pos) rails.action_view.HtmlAttr.Bool($v{name}),
				pos: pos
			};
		}
		i++;
		skipWs();
		if (startsWith("\"") || startsWith("'")) {
			var quote = ch(i);
			i++;
			var valueStart = i;
			while (!eof() && ch(i) != quote) {
				i++;
			}
			if (eof()) {
				Context.error("Unclosed attribute string", makeSubPos(valueStart, i));
			}
			var value = src.substr(valueStart, i - valueStart);
			i++;
			var pos2 = makeSubPos(attrStart, i);
			return {
				name: name,
				kind: Static(value),
				expr: macro @:pos(pos2) rails.action_view.HtmlAttr.Static($v{name}, $v{value}),
				pos: pos2
			};
		}
		if (startsWith("${") || startsWith("{")) {
			var expr = parseExprInBraces();
			var pos3 = makeSubPos(attrStart, i);
			return {
				name: name,
				kind: ExprValue(expr),
				expr: macro @:pos(pos3) rails.action_view.HtmlAttr.Expr($v{name}, $expr),
				pos: pos3
			};
		}
		failHere("Expected quoted string or ${...} attribute value");
		return null;
	}

	function lowerTag(name:String, attrs:Array<RailsParsedAttr>, children:Array<Expr>, pos:Position):Expr {
		return switch (name) {
			case "doctype_html":
				rejectChildren(name, children, pos);
				rejectAttrs(name, attrs, pos);
				macro @:pos(pos) rails.action_view.HtmlNode.DoctypeHtml;
			case "form_with":
				var url = requireAttrValue(attrs, "url", pos);
				var scope = requireAttrValue(attrs, "scope", pos);
				var helperAttrs = attrsExcept(attrs, ["url", "scope"]);
				macro @:pos(pos) rails.action_view.HtmlNode.FormWith($url, $scope, ${mkArray(helperAttrs.map(mkAttr), pos)}, ${mkArray(children, pos)});
			case "hidden_field":
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = requireAttrValue(attrs, "value", pos);
				macro @:pos(pos) rails.action_view.HtmlNode.FormHiddenField($fieldName, $value);
			case "field_label":
				var labelName = requireAttrValue(attrs, "name", pos);
				var text = attrValueOrTextChildren(attrs, children, "field_label", pos);
				var labelAttrs = attrsExcept(attrs, ["name", "text"]);
				macro @:pos(pos) rails.action_view.HtmlNode.FormLabel($labelName, $text, ${mkArray(labelAttrs.map(mkAttr), pos)});
			case "text_field":
				var textFieldName = requireAttrValue(attrs, "name", pos);
				var textFieldAttrs = attrsExcept(attrs, ["name"]);
				macro @:pos(pos) rails.action_view.HtmlNode.FormTextField($textFieldName, ${mkArray(textFieldAttrs.map(mkAttr), pos)});
			case "password_field":
				var passwordFieldName = requireAttrValue(attrs, "name", pos);
				var passwordFieldAttrs = attrsExcept(attrs, ["name"]);
				macro @:pos(pos) rails.action_view.HtmlNode.FormPasswordField($passwordFieldName, ${mkArray(passwordFieldAttrs.map(mkAttr), pos)});
			case "file_field":
				var fileFieldName = requireAttrValue(attrs, "name", pos);
				var fileFieldAttrs = attrsExcept(attrs, ["name"]);
				macro @:pos(pos) rails.action_view.HtmlNode.FormFileField($fileFieldName, ${mkArray(fileFieldAttrs.map(mkAttr), pos)});
			case "text_area":
				var textAreaName = requireAttrValue(attrs, "name", pos);
				var textAreaAttrs = attrsExcept(attrs, ["name"]);
				macro @:pos(pos) rails.action_view.HtmlNode.FormTextArea($textAreaName, ${mkArray(textAreaAttrs.map(mkAttr), pos)});
			case "check_box":
				var checkBoxName = requireAttrValue(attrs, "name", pos);
				var checkBoxAttrs = attrsExcept(attrs, ["name"]);
				macro @:pos(pos) rails.action_view.HtmlNode.FormCheckBox($checkBoxName, ${mkArray(checkBoxAttrs.map(mkAttr), pos)});
			case "field_errors":
				rejectChildren(name, children, pos);
				var errorFieldName = requireAttrValue(attrs, "name", pos);
				var errorAttrs = attrsExcept(attrs, ["name"]);
				macro @:pos(pos) rails.action_view.HtmlNode.FormFieldErrors($errorFieldName, ${mkArray(errorAttrs.map(mkAttr), pos)});
			case "submit":
				var submitText = attrValueOrTextChildren(attrs, children, "submit", pos);
				var submitAttrs = attrsExcept(attrs, ["text"]);
				macro @:pos(pos) rails.action_view.HtmlNode.FormSubmit($submitText, ${mkArray(submitAttrs.map(mkAttr), pos)});
			case "link_to":
				var url = requireAttrValue(attrs, "url", pos);
				var linkAttrs = attrsExcept(attrs, ["text", "url"]);
				var explicitText = attrValue(attrs, "text");
				if (explicitText != null) {
					macro @:pos(pos) rails.action_view.HtmlNode.LinkTo($explicitText, $url, ${mkArray(linkAttrs.map(mkAttr), pos)});
				} else {
					var label = textChildExpr(children, pos);
					if (label != null) {
						macro @:pos(pos) rails.action_view.HtmlNode.LinkTo($label, $url, ${mkArray(linkAttrs.map(mkAttr), pos)});
					} else if (children.length > 0) {
						macro @:pos(pos) rails.action_view.HtmlNode.LinkToBlock($url, ${mkArray(linkAttrs.map(mkAttr), pos)}, ${mkArray(children, pos)});
					} else {
						Context.error('Rails HHX <link_to> expects text/expression children, text="...", or nested markup children.', pos);
						macro null;
					}
				}
			case "image_tag":
				rejectChildren(name, children, pos);
				var src = attrValue(attrs, "src");
				var source = attrValue(attrs, "source");
				if (src != null && source != null) {
					Context.error('Rails HHX <image_tag> accepts src=... or source=..., not both.', pos);
				}
				if (src == null && source == null) {
					Context.error('Rails HHX <image_tag> expects src=... or source=....', pos);
				}
				var imageSource = src == null ? source : src;
				var imageAttrs = attrsExcept(attrs, ["src", "source"]);
				macro @:pos(pos) rails.action_view.HtmlNode.ImageTag($imageSource, ${mkArray(imageAttrs.map(mkAttr), pos)});
			case "picture_tag":
				rejectChildren(name, children, pos);
				var src = attrValue(attrs, "src");
				var source = attrValue(attrs, "source");
				if (src != null && source != null) {
					Context.error('Rails HHX <picture_tag> accepts src=... or source=..., not both.', pos);
				}
				if (src == null && source == null) {
					Context.error('Rails HHX <picture_tag> expects src=... or source=....', pos);
				}
				var pictureSource = src == null ? source : src;
				var pictureAttrs = attrsExcept(attrs, ["src", "source"]);
				macro @:pos(pos) rails.action_view.HtmlNode.PictureTag($pictureSource, ${mkArray(pictureAttrs.map(mkAttr), pos)});
			case "favicon_link_tag":
				rejectChildren(name, children, pos);
				var src = attrValue(attrs, "src");
				var source = attrValue(attrs, "source");
				if (src != null && source != null) {
					Context.error('Rails HHX <favicon_link_tag> accepts src=... or source=..., not both.', pos);
				}
				if (src == null && source == null) {
					Context.error('Rails HHX <favicon_link_tag> expects src=... or source=....', pos);
				}
				var faviconSource = src == null ? source : src;
				var faviconAttrs = attrsExcept(attrs, ["src", "source"]);
				macro @:pos(pos) rails.action_view.HtmlNode.FaviconLinkTag($faviconSource, ${mkArray(faviconAttrs.map(mkAttr), pos)});
			case "preload_link_tag":
				rejectChildren(name, children, pos);
				var src = attrValue(attrs, "src");
				var source = attrValue(attrs, "source");
				if (src != null && source != null) {
					Context.error('Rails HHX <preload_link_tag> accepts src=... or source=..., not both.', pos);
				}
				if (src == null && source == null) {
					Context.error('Rails HHX <preload_link_tag> expects src=... or source=....', pos);
				}
				var preloadSource = src == null ? source : src;
				var preloadAttrs = attrsExcept(attrs, ["src", "source"]);
				macro @:pos(pos) rails.action_view.HtmlNode.PreloadLinkTag($preloadSource, ${mkArray(preloadAttrs.map(mkAttr), pos)});
			case "javascript_include_tag":
				rejectChildren(name, children, pos);
				var src = attrValue(attrs, "src");
				var source = attrValue(attrs, "source");
				if (src != null && source != null) {
					Context.error('Rails HHX <javascript_include_tag> accepts src=... or source=..., not both.', pos);
				}
				if (src == null && source == null) {
					Context.error('Rails HHX <javascript_include_tag> expects src=... or source=....', pos);
				}
				var scriptSource = src == null ? source : src;
				var scriptAttrs = attrsExcept(attrs, ["src", "source"]);
				macro @:pos(pos) rails.action_view.HtmlNode.JavascriptIncludeTag($scriptSource, ${mkArray(scriptAttrs.map(mkAttr), pos)});
			case "javascript_tag":
				rejectChildren(name, children, pos);
				var content = requireAttrValue(attrs, "content", pos);
				var scriptAttrs = attrsExcept(attrs, ["content"]);
				macro @:pos(pos) rails.action_view.HtmlNode.JavascriptTag($content, ${mkArray(scriptAttrs.map(mkAttr), pos)});
			case "auto_discovery_link_tag":
				rejectChildren(name, children, pos);
				var feedType = requireAttrValue(attrs, "type", pos);
				var url = requireAttrValue(attrs, "url", pos);
				var feedAttrs = attrsExcept(attrs, ["type", "url"]);
				macro @:pos(pos) rails.action_view.HtmlNode.AutoDiscoveryLinkTag($feedType, $url, ${mkArray(feedAttrs.map(mkAttr), pos)});
			case "audio_tag":
				rejectChildren(name, children, pos);
				var src = attrValue(attrs, "src");
				var source = attrValue(attrs, "source");
				if (src != null && source != null) {
					Context.error('Rails HHX <audio_tag> accepts src=... or source=..., not both.', pos);
				}
				if (src == null && source == null) {
					Context.error('Rails HHX <audio_tag> expects src=... or source=....', pos);
				}
				var audioSource = src == null ? source : src;
				var audioAttrs = attrsExcept(attrs, ["src", "source"]);
				macro @:pos(pos) rails.action_view.HtmlNode.AudioTag($audioSource, ${mkArray(audioAttrs.map(mkAttr), pos)});
			case "video_tag":
				rejectChildren(name, children, pos);
				var src = attrValue(attrs, "src");
				var source = attrValue(attrs, "source");
				if (src != null && source != null) {
					Context.error('Rails HHX <video_tag> accepts src=... or source=..., not both.', pos);
				}
				if (src == null && source == null) {
					Context.error('Rails HHX <video_tag> expects src=... or source=....', pos);
				}
				var videoSource = src == null ? source : src;
				var videoAttrs = attrsExcept(attrs, ["src", "source"]);
				macro @:pos(pos) rails.action_view.HtmlNode.VideoTag($videoSource, ${mkArray(videoAttrs.map(mkAttr), pos)});
			case "mail_to":
				var email = requireAttrValue(attrs, "email", pos);
				var explicitText = attrValue(attrs, "text");
				var label = explicitText == null ? textChildExpr(children, pos) : explicitText;
				if (label == null && children.length > 0) {
					Context.error('Rails HHX <mail_to> accepts only text/expression children when text=... is omitted.', pos);
				}
				var mailAttrs = attrsExcept(attrs, ["email", "text"]);
				macro @:pos(pos) rails.action_view.HtmlNode.MailTo($email, ${label == null ? (macro null) : label}, ${mkArray(mailAttrs.map(mkAttr), pos)});
			case "phone_to":
				var phone = requireAttrValue(attrs, "phone", pos);
				var explicitText = attrValue(attrs, "text");
				var label = explicitText == null ? textChildExpr(children, pos) : explicitText;
				if (label == null && children.length > 0) {
					Context.error('Rails HHX <phone_to> accepts only text/expression children when text=... is omitted.', pos);
				}
				var phoneAttrs = attrsExcept(attrs, ["phone", "text"]);
				macro @:pos(pos) rails.action_view.HtmlNode.PhoneTo($phone, ${label == null ? (macro null) : label},
					${mkArray(phoneAttrs.map(mkAttr), pos)});
			case "sms_to":
				var phone = requireAttrValue(attrs, "phone", pos);
				var explicitText = attrValue(attrs, "text");
				var label = explicitText == null ? textChildExpr(children, pos) : explicitText;
				if (label == null && children.length > 0) {
					Context.error('Rails HHX <sms_to> accepts only text/expression children when text=... is omitted.', pos);
				}
				var smsAttrs = attrsExcept(attrs, ["phone", "text"]);
				macro @:pos(pos) rails.action_view.HtmlNode.SmsTo($phone, ${label == null ? (macro null) : label}, ${mkArray(smsAttrs.map(mkAttr), pos)});
			case "pluralize":
				rejectChildren(name, children, pos);
				var count = requireAttrValue(attrs, "count", pos);
				var singular = requireAttrValue(attrs, "singular", pos);
				var plural = attrValue(attrs, "plural");
				rejectUnknownAttrs(name, attrs, ["count", "singular", "plural"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.Pluralize($count, $singular, ${plural == null ? (macro null) : plural});
			case "simple_format":
				rejectChildren(name, children, pos);
				var text = requireAttrValue(attrs, "text", pos);
				var simpleFormatAttrs = attrsExcept(attrs, ["text"]);
				macro @:pos(pos) rails.action_view.HtmlNode.SimpleFormat($text, ${mkArray(simpleFormatAttrs.map(mkAttr), pos)});
			case "truncate":
				rejectChildren(name, children, pos);
				var text = requireAttrValue(attrs, "text", pos);
				var length = attrValue(attrs, "length");
				var omission = attrValue(attrs, "omission");
				rejectUnknownAttrs(name, attrs, ["text", "length", "omission"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.Truncate($text, ${length == null ? (macro null) : length},
					${omission == null ? (macro null) : omission});
			case "excerpt":
				rejectChildren(name, children, pos);
				var text = requireAttrValue(attrs, "text", pos);
				var phrase = requireAttrValue(attrs, "phrase", pos);
				var radius = attrValue(attrs, "radius");
				var omission = attrValue(attrs, "omission");
				rejectUnknownAttrs(name, attrs, ["text", "phrase", "radius", "omission"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.Excerpt($text, $phrase, ${radius == null ? (macro null) : radius},
					${omission == null ? (macro null) : omission});
			case "highlight":
				rejectChildren(name, children, pos);
				var text = requireAttrValue(attrs, "text", pos);
				var phrase = requireAttrValue(attrs, "phrase", pos);
				var highlighter = attrValue(attrs, "highlighter");
				var sanitize = attrValue(attrs, "sanitize");
				rejectUnknownAttrs(name, attrs, ["text", "phrase", "highlighter", "sanitize"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.Highlight($text, $phrase, ${highlighter == null ? (macro null) : highlighter},
					${sanitize == null ? (macro null) : sanitize});
			case "word_wrap":
				rejectChildren(name, children, pos);
				var text = requireAttrValue(attrs, "text", pos);
				var lineWidth = attrValue(attrs, "line_width");
				var breakSequence = attrValue(attrs, "break_sequence");
				rejectUnknownAttrs(name, attrs, ["text", "line_width", "break_sequence"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.WordWrap($text, ${lineWidth == null ? (macro null) : lineWidth},
					${breakSequence == null ? (macro null) : breakSequence});
			case "sanitize":
				rejectChildren(name, children, pos);
				var html = requireAttrValue(attrs, "html", pos);
				var tags = attrValue(attrs, "tags");
				var attributes = attrValue(attrs, "attributes");
				rejectUnknownAttrs(name, attrs, ["html", "tags", "attributes"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.Sanitize($html, ${tags == null ? (macro null) : tags},
					${attributes == null ? (macro null) : attributes});
			case "sanitize_css":
				rejectChildren(name, children, pos);
				var style = requireAttrValue(attrs, "style", pos);
				rejectUnknownAttrs(name, attrs, ["style"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.SanitizeCss($style);
			case "strip_tags":
				rejectChildren(name, children, pos);
				var html = requireAttrValue(attrs, "html", pos);
				rejectUnknownAttrs(name, attrs, ["html"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.StripTags($html);
			case "strip_links":
				rejectChildren(name, children, pos);
				var html = requireAttrValue(attrs, "html", pos);
				rejectUnknownAttrs(name, attrs, ["html"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.StripLinks($html);
			case "to_sentence":
				rejectChildren(name, children, pos);
				var items = requireAttrValue(attrs, "items", pos);
				var wordsConnector = attrValue(attrs, "words_connector");
				var twoWordsConnector = attrValue(attrs, "two_words_connector");
				var lastWordConnector = attrValue(attrs, "last_word_connector");
				rejectUnknownAttrs(name, attrs, ["items", "words_connector", "two_words_connector", "last_word_connector"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.ToSentence($items, ${wordsConnector == null ? (macro null) : wordsConnector},
					${twoWordsConnector == null ? (macro null) : twoWordsConnector},
					${lastWordConnector == null ? (macro null) : lastWordConnector});
			case "escape_once":
				rejectChildren(name, children, pos);
				var html = requireAttrValue(attrs, "html", pos);
				rejectUnknownAttrs(name, attrs, ["html"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.EscapeOnce($html);
			case "cdata_section":
				rejectChildren(name, children, pos);
				var content = requireAttrValue(attrs, "content", pos);
				rejectUnknownAttrs(name, attrs, ["content"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.CdataSection($content);
			case "safe_join":
				rejectChildren(name, children, pos);
				var items = requireAttrValue(attrs, "items", pos);
				var separator = attrValue(attrs, "separator");
				rejectUnknownAttrs(name, attrs, ["items", "separator"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.SafeJoin($items, ${separator == null ? (macro null) : separator});
			case "token_list":
				rejectChildren(name, children, pos);
				var tokens = requireAttrValue(attrs, "tokens", pos);
				rejectUnknownAttrs(name, attrs, ["tokens"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.TokenList($tokens);
			case "class_names":
				rejectChildren(name, children, pos);
				var tokens = requireAttrValue(attrs, "tokens", pos);
				rejectUnknownAttrs(name, attrs, ["tokens"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.ClassNames($tokens);
			case "cycle":
				rejectChildren(name, children, pos);
				var values = requireAttrValue(attrs, "values", pos);
				var cycleName = attrValue(attrs, "name");
				rejectUnknownAttrs(name, attrs, ["values", "name"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.Cycle($values, ${cycleName == null ? (macro null) : cycleName});
			case "current_cycle":
				rejectChildren(name, children, pos);
				var cycleName = attrValue(attrs, "name");
				rejectUnknownAttrs(name, attrs, ["name"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.CurrentCycle(${cycleName == null ? (macro null) : cycleName});
			case "reset_cycle":
				rejectChildren(name, children, pos);
				var cycleName = attrValue(attrs, "name");
				rejectUnknownAttrs(name, attrs, ["name"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.ResetCycle(${cycleName == null ? (macro null) : cycleName});
			case "time_ago_in_words":
				rejectChildren(name, children, pos);
				var from = requireAttrValue(attrs, "from", pos);
				var includeSeconds = attrValue(attrs, "include_seconds");
				rejectUnknownAttrs(name, attrs, ["from", "include_seconds"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.TimeAgoInWords($from, ${includeSeconds == null ? (macro null) : includeSeconds});
			case "distance_of_time_in_words":
				rejectChildren(name, children, pos);
				var from = requireAttrValue(attrs, "from", pos);
				var to = requireAttrValue(attrs, "to", pos);
				var includeSeconds = attrValue(attrs, "include_seconds");
				rejectUnknownAttrs(name, attrs, ["from", "to", "include_seconds"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.DistanceOfTimeInWords($from, $to,
					${includeSeconds == null ? (macro null) : includeSeconds});
			case "time_tag":
				rejectChildren(name, children, pos);
				var time = requireAttrValue(attrs, "time", pos);
				var label = attrValue(attrs, "text");
				var timeTagAttrs = attrsExcept(attrs, ["time", "text"]);
				macro @:pos(pos) rails.action_view.HtmlNode.TimeTag($time, ${label == null ? (macro null) : label},
					${mkArray(timeTagAttrs.map(mkAttr), pos)});
			case "number_to_currency":
				rejectChildren(name, children, pos);
				var number = requireAttrValue(attrs, "number", pos);
				var unit = attrValue(attrs, "unit");
				var precision = attrValue(attrs, "precision");
				rejectUnknownAttrs(name, attrs, ["number", "unit", "precision"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.NumberToCurrency($number, ${unit == null ? (macro null) : unit},
					${precision == null ? (macro null) : precision});
			case "number_to_percentage":
				rejectChildren(name, children, pos);
				var number = requireAttrValue(attrs, "number", pos);
				var precision = attrValue(attrs, "precision");
				rejectUnknownAttrs(name, attrs, ["number", "precision"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.NumberToPercentage($number, ${precision == null ? (macro null) : precision});
			case "number_to_human":
				rejectChildren(name, children, pos);
				var number = requireAttrValue(attrs, "number", pos);
				var precision = attrValue(attrs, "precision");
				rejectUnknownAttrs(name, attrs, ["number", "precision"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.NumberToHuman($number, ${precision == null ? (macro null) : precision});
			case "number_to_human_size":
				rejectChildren(name, children, pos);
				var number = requireAttrValue(attrs, "number", pos);
				var precision = attrValue(attrs, "precision");
				rejectUnknownAttrs(name, attrs, ["number", "precision"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.NumberToHumanSize($number, ${precision == null ? (macro null) : precision});
			case "number_with_precision":
				rejectChildren(name, children, pos);
				var number = requireAttrValue(attrs, "number", pos);
				var precision = attrValue(attrs, "precision");
				var significant = attrValue(attrs, "significant");
				var delimiter = attrValue(attrs, "delimiter");
				var separator = attrValue(attrs, "separator");
				var stripInsignificantZeros = attrValue(attrs, "strip_insignificant_zeros");
				rejectUnknownAttrs(name, attrs, ["number", "precision", "significant", "delimiter", "separator", "strip_insignificant_zeros"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.NumberWithPrecision($number, ${precision == null ? (macro null) : precision},
					${significant == null ? (macro null) : significant}, ${delimiter == null ? (macro null) : delimiter},
					${separator == null ? (macro null) : separator}, ${stripInsignificantZeros == null ? (macro null) : stripInsignificantZeros});
			case "number_with_delimiter":
				rejectChildren(name, children, pos);
				var number = requireAttrValue(attrs, "number", pos);
				var delimiter = attrValue(attrs, "delimiter");
				var separator = attrValue(attrs, "separator");
				rejectUnknownAttrs(name, attrs, ["number", "delimiter", "separator"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.NumberWithDelimiter($number, ${delimiter == null ? (macro null) : delimiter},
					${separator == null ? (macro null) : separator});
			case "number_to_delimited":
				rejectChildren(name, children, pos);
				var number = requireAttrValue(attrs, "number", pos);
				var delimiter = attrValue(attrs, "delimiter");
				var separator = attrValue(attrs, "separator");
				rejectUnknownAttrs(name, attrs, ["number", "delimiter", "separator"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.NumberToDelimited($number, ${delimiter == null ? (macro null) : delimiter},
					${separator == null ? (macro null) : separator});
			case "number_to_phone":
				rejectChildren(name, children, pos);
				var number = requireAttrValue(attrs, "number", pos);
				var areaCode = attrValue(attrs, "area_code");
				var delimiter = attrValue(attrs, "delimiter");
				var extension = attrValue(attrs, "extension");
				var countryCode = attrValue(attrs, "country_code");
				rejectUnknownAttrs(name, attrs, ["number", "area_code", "delimiter", "extension", "country_code"], pos);
				macro @:pos(pos) rails.action_view.HtmlNode.NumberToPhone($number, ${areaCode == null ? (macro null) : areaCode},
					${delimiter == null ? (macro null) : delimiter}, ${extension == null ? (macro null) : extension},
					${countryCode == null ? (macro null) : countryCode});
			case "button_tag":
				var buttonAttrs = attrsExcept(attrs, ["text"]);
				var explicitText = attrValue(attrs, "text");
				var content = explicitText == null ? textChildExpr(children, pos) : explicitText;
				if (content == null) {
					if (children.length > 0) {
						Context.error('Rails HHX <button_tag> accepts only text/expression children when text="..." is omitted.', pos);
					} else {
						Context.error('Rails HHX <button_tag> expects text="..." or text/expression children.', pos);
					}
					macro null;
				} else {
					macro @:pos(pos) rails.action_view.HtmlNode.ButtonTag($content, ${mkArray(buttonAttrs.map(mkAttr), pos)});
				}
			case "submit_tag":
				var submitAttrs = attrsExcept(attrs, ["value", "text"]);
				var value = attrValue(attrs, "value");
				var text = attrValue(attrs, "text");
				if (value != null && text != null) {
					Context.error('Rails HHX <submit_tag> accepts value=... or text=..., not both.', pos);
				}
				var submitValue = value != null ? value : (text != null ? text : textChildExpr(children, pos));
				if (submitValue == null) {
					if (children.length > 0) {
						Context.error('Rails HHX <submit_tag> accepts only text/expression children when value=... or text=... is omitted.', pos);
					} else {
						Context.error('Rails HHX <submit_tag> expects value=..., text=..., or text/expression children.', pos);
					}
					macro null;
				} else {
					macro @:pos(pos) rails.action_view.HtmlNode.SubmitTag($submitValue, ${mkArray(submitAttrs.map(mkAttr), pos)});
				}
			case "text_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var fieldAttrs = attrsExcept(attrs, ["name", "value"]);
				macro @:pos(pos) rails.action_view.HtmlNode.TextFieldTag($fieldName, ${value == null ? (macro null) : value},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "search_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var fieldAttrs = attrsExcept(attrs, ["name", "value"]);
				macro @:pos(pos) rails.action_view.HtmlNode.SearchFieldTag($fieldName, ${value == null ? (macro null) : value},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "email_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var fieldAttrs = attrsExcept(attrs, ["name", "value"]);
				macro @:pos(pos) rails.action_view.HtmlNode.EmailFieldTag($fieldName, ${value == null ? (macro null) : value},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "telephone_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var fieldAttrs = attrsExcept(attrs, ["name", "value"]);
				macro @:pos(pos) rails.action_view.HtmlNode.TelephoneFieldTag($fieldName, ${value == null ? (macro null) : value},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "url_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var fieldAttrs = attrsExcept(attrs, ["name", "value"]);
				macro @:pos(pos) rails.action_view.HtmlNode.UrlFieldTag($fieldName, ${value == null ? (macro null) : value},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "number_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var fieldAttrs = attrsExcept(attrs, ["name", "value"]);
				macro @:pos(pos) rails.action_view.HtmlNode.NumberFieldTag($fieldName, ${value == null ? (macro null) : value},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "range_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var fieldAttrs = attrsExcept(attrs, ["name", "value"]);
				macro @:pos(pos) rails.action_view.HtmlNode.RangeFieldTag($fieldName, ${value == null ? (macro null) : value},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "color_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var fieldAttrs = attrsExcept(attrs, ["name", "value"]);
				macro @:pos(pos) rails.action_view.HtmlNode.ColorFieldTag($fieldName, ${value == null ? (macro null) : value},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "date_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var fieldAttrs = attrsExcept(attrs, ["name", "value"]);
				macro @:pos(pos) rails.action_view.HtmlNode.DateFieldTag($fieldName, ${value == null ? (macro null) : value},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "time_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var fieldAttrs = attrsExcept(attrs, ["name", "value"]);
				macro @:pos(pos) rails.action_view.HtmlNode.TimeFieldTag($fieldName, ${value == null ? (macro null) : value},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "datetime_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var fieldAttrs = attrsExcept(attrs, ["name", "value"]);
				macro @:pos(pos) rails.action_view.HtmlNode.DatetimeFieldTag($fieldName, ${value == null ? (macro null) : value},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "month_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var fieldAttrs = attrsExcept(attrs, ["name", "value"]);
				macro @:pos(pos) rails.action_view.HtmlNode.MonthFieldTag($fieldName, ${value == null ? (macro null) : value},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "week_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var fieldAttrs = attrsExcept(attrs, ["name", "value"]);
				macro @:pos(pos) rails.action_view.HtmlNode.WeekFieldTag($fieldName, ${value == null ? (macro null) : value},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "password_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var fieldAttrs = attrsExcept(attrs, ["name", "value"]);
				macro @:pos(pos) rails.action_view.HtmlNode.PasswordFieldTag($fieldName, ${value == null ? (macro null) : value},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "hidden_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var fieldAttrs = attrsExcept(attrs, ["name", "value"]);
				macro @:pos(pos) rails.action_view.HtmlNode.HiddenFieldTag($fieldName, ${value == null ? (macro null) : value},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "file_field_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var fieldAttrs = attrsExcept(attrs, ["name"]);
				macro @:pos(pos) rails.action_view.HtmlNode.FileFieldTag($fieldName, ${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "text_area_tag":
				var fieldName = requireAttrValue(attrs, "name", pos);
				var contentAttr = attrValue(attrs, "content");
				var valueAttr = attrValue(attrs, "value");
				if (contentAttr != null && valueAttr != null) {
					Context.error('Rails HHX <text_area_tag> accepts content=... or value=..., not both.', pos);
				}
				var content = contentAttr != null ? contentAttr : (valueAttr != null ? valueAttr : textChildExpr(children, pos));
				var fieldAttrs = attrsExcept(attrs, ["name", "content", "value"]);
				if (content == null && children.length > 0) {
					Context.error('Rails HHX <text_area_tag> accepts only text/expression children when content=... or value=... is omitted.', pos);
					macro null;
				} else {
					macro @:pos(pos) rails.action_view.HtmlNode.TextAreaTag($fieldName, ${content == null ? (macro null) : content},
						${mkArray(fieldAttrs.map(mkAttr), pos)});
				}
			case "check_box_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = attrValue(attrs, "value");
				var checked = attrValue(attrs, "checked");
				var fieldAttrs = attrsExcept(attrs, ["name", "value", "checked"]);
				macro @:pos(pos) rails.action_view.HtmlNode.CheckBoxTag($fieldName, ${value == null ? (macro null) : value},
					${checked == null ? (macro null) : checked}, ${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "radio_button_tag":
				rejectChildren(name, children, pos);
				var fieldName = requireAttrValue(attrs, "name", pos);
				var value = requireAttrValue(attrs, "value", pos);
				var checked = attrValue(attrs, "checked");
				var fieldAttrs = attrsExcept(attrs, ["name", "value", "checked"]);
				macro @:pos(pos) rails.action_view.HtmlNode.RadioButtonTag($fieldName, $value, ${checked == null ? (macro null) : checked},
					${mkArray(fieldAttrs.map(mkAttr), pos)});
			case "button_to":
				var url = requireAttrValue(attrs, "url", pos);
				var buttonAttrs = attrsExcept(attrs, ["text", "url"]);
				var explicitText = attrValue(attrs, "text");
				if (explicitText != null) {
					macro @:pos(pos) rails.action_view.HtmlNode.ButtonTo($explicitText, $url, ${mkArray(buttonAttrs.map(mkAttr), pos)});
				} else {
					var label = textChildExpr(children, pos);
					if (label != null) {
						macro @:pos(pos) rails.action_view.HtmlNode.ButtonTo($label, $url, ${mkArray(buttonAttrs.map(mkAttr), pos)});
					} else if (children.length > 0) {
						macro @:pos(pos) rails.action_view.HtmlNode.ButtonToBlock($url, ${mkArray(buttonAttrs.map(mkAttr), pos)}, ${mkArray(children, pos)});
					} else {
						Context.error('Rails HHX <button_to> expects text/expression children, text="...", or nested markup children.', pos);
						macro null;
					}
				}
			case "devise_sign_in_link":
				lowerDeviseLinkTag(name, "signInPath", attrs, children, pos);
			case "devise_sign_up_link":
				lowerDeviseLinkTag(name, "signUpPath", attrs, children, pos);
			case "devise_edit_registration_link":
				lowerDeviseLinkTag(name, "editRegistrationPath", attrs, children, pos);
			case "devise_sign_out_button":
				if (attrValue(attrs, "method") != null) {
					Context.error("Rails HHX <devise_sign_out_button> always uses method=\"delete\". Remove the method attribute or use <button_to> with AuthLinks.signOutPath(...) for a lower-level override.",
						pos);
				}
				var scope = requireAttrValue(attrs, "scope", pos);
				var label = attrValueOrTextChildren(attrs, children, name, pos);
				var buttonAttrs = attrsExcept(attrs, ["scope", "text", "method"]);
				buttonAttrs.unshift(staticAttr("method", "delete", pos));
				macro @:pos(pos) rails.action_view.HtmlNode.ButtonTo($label, devisehx.hhx.AuthLinks.signOutPath($scope),
					${mkArray(buttonAttrs.map(mkAttr), pos)});
			case "partial":
				var template = requireAttrValue(attrs, "template", pos);
				var locals = requireAttrValue(attrs, "locals", pos);
				macro @:pos(pos) rails.action_view.HtmlNode.Partial($template, $locals);
			case "component":
				var component = attrValue(attrs, "component");
				if (component != null) {
					var locals = requireAttrValue(attrs, "locals", pos);
					rejectAttrs(name, attrsExcept(attrs, ["component", "locals"]), pos);
					macro @:pos(pos) rails.action_view.HtmlNode.ComponentRef($component, $locals, ${mkArray(children, pos)});
				} else {
					var template = requireAttrValue(attrs, "template", pos);
					var locals = requireAttrValue(attrs, "locals", pos);
					var slot = requireAttrValue(attrs, "slot", pos);
					rejectAttrs(name, attrsExcept(attrs, ["template", "locals", "slot"]), pos);
					macro @:pos(pos) rails.action_view.HtmlNode.Component($template, $locals, $slot, ${mkArray(children, pos)});
				}
			case "csrf_meta_tags":
				rejectChildren(name, children, pos);
				rejectAttrs(name, attrs, pos);
				macro @:pos(pos) rails.action_view.HtmlNode.CsrfMetaTags;
			case "csp_meta_tag":
				rejectChildren(name, children, pos);
				rejectAttrs(name, attrs, pos);
				macro @:pos(pos) rails.action_view.HtmlNode.CspMetaTag;
			case "stylesheet_link_tag":
				rejectChildren(name, children, pos);
				var stylesheet = requireAttrValue(attrs, "name", pos);
				var stylesheetAttrs = attrsExcept(attrs, ["name"]);
				macro @:pos(pos) rails.action_view.HtmlNode.StylesheetLinkTag($stylesheet, ${mkArray(stylesheetAttrs.map(mkAttr), pos)});
			case "javascript_importmap_tags":
				rejectChildren(name, children, pos);
				rejectAttrs(name, attrs, pos);
				macro @:pos(pos) rails.action_view.HtmlNode.JavascriptImportmapTags;
			case "turbo_stream_from":
				rejectChildren(name, children, pos);
				var stream = requireAttrValue(attrs, "stream", pos);
				rejectAttrs(name, attrsExcept(attrs, ["stream"]), pos);
				macro @:pos(pos) rails.action_view.HtmlNode.TurboStreamFrom($stream);
			case "turbo_frame":
				var id = requireAttrValue(attrs, "id", pos);
				var frameAttrs = attrsExcept(attrs, ["id"]);
				macro @:pos(pos) rails.action_view.HtmlNode.TurboFrame($id, ${mkArray(frameAttrs.map(mkAttr), pos)}, ${mkArray(children, pos)});
			case "rails_yield":
				rejectChildren(name, children, pos);
				rejectAttrs(name, attrs, pos);
				macro @:pos(pos) rails.action_view.HtmlNode.Yield;
			case "content_for":
				var slotName = requireAttrValue(attrs, "name", pos);
				rejectAttrs(name, attrsExcept(attrs, ["name"]), pos);
				macro @:pos(pos) rails.action_view.HtmlNode.ContentFor($slotName, ${mkArray(children, pos)});
			case "yield_content":
				rejectChildren(name, children, pos);
				var slotName = requireAttrValue(attrs, "name", pos);
				rejectAttrs(name, attrsExcept(attrs, ["name"]), pos);
				macro @:pos(pos) rails.action_view.HtmlNode.YieldContent($slotName);
			default:
				mkElement(name, attrs.map(mkAttr), children, pos);
		}
	}

	function lowerDeviseLinkTag(tagName:String, helperName:String, attrs:Array<RailsParsedAttr>, children:Array<Expr>, pos:Position):Expr {
		var scope = requireAttrValue(attrs, "scope", pos);
		var label = attrValueOrTextChildren(attrs, children, tagName, pos);
		var linkAttrs = attrsExcept(attrs, ["scope", "text"]);
		var url = switch (helperName) {
			case "signInPath":
				macro @:pos(pos) devisehx.hhx.AuthLinks.signInPath($scope);
			case "signUpPath":
				macro @:pos(pos) devisehx.hhx.AuthLinks.signUpPath($scope);
			case "editRegistrationPath":
				macro @:pos(pos) devisehx.hhx.AuthLinks.editRegistrationPath($scope);
			case _:
				Context.error('Unsupported DeviseHx HHX link helper "$helperName".', pos);
				macro null;
		}
		return macro @:pos(pos) rails.action_view.HtmlNode.LinkTo($label, $url, ${mkArray(linkAttrs.map(mkAttr), pos)});
	}

	function rejectAttrs(tagName:String, attrs:Array<RailsParsedAttr>, pos:Position):Void {
		if (attrs.length > 0) {
			Context.error('Rails HHX <' + tagName + '> does not accept attributes yet.', pos);
		}
	}

	function rejectUnknownAttrs(tagName:String, attrs:Array<RailsParsedAttr>, allowed:Array<String>, pos:Position):Void {
		var known = new Map<String, Bool>();
		for (name in allowed) {
			known.set(name, true);
		}
		for (attr in attrs) {
			if (!known.exists(attr.name)) {
				Context.error('Rails HHX <' + tagName + '> does not accept attribute "' + attr.name + '".', attr.pos);
			}
		}
	}

	function rejectChildren(tagName:String, children:Array<Expr>, pos:Position):Void {
		if (children.length > 0) {
			Context.error('Rails HHX <' + tagName + '> must be self-closing.', pos);
		}
	}

	function attrsExcept(attrs:Array<RailsParsedAttr>, names:Array<String>):Array<RailsParsedAttr> {
		var skip = new Map<String, Bool>();
		for (name in names) {
			skip.set(name, true);
		}
		return [for (attr in attrs) if (!skip.exists(attr.name)) attr];
	}

	function requireAttrValue(attrs:Array<RailsParsedAttr>, name:String, pos:Position):Expr {
		var found = attrValue(attrs, name);
		if (found != null) {
			return found;
		}
		Context.error('Rails HHX <' + name + '> attribute is required here.', pos);
		return macro null;
	}

	function attrValue(attrs:Array<RailsParsedAttr>, name:String):Null<Expr> {
		for (attr in attrs) {
			if (attr.name == name) {
				return attrValueExpr(attr);
			}
		}
		return null;
	}

	function attrValueOrTextChildren(attrs:Array<RailsParsedAttr>, children:Array<Expr>, tagName:String, pos:Position):Expr {
		for (attr in attrs) {
			if (attr.name == "text") {
				return attrValueExpr(attr);
			}
		}
		var childValue = textChildExpr(children, pos);
		if (childValue != null) {
			return childValue;
		}
		Context.error('Rails HHX <' + tagName + '> expects a text="..." attribute or text/expression children.', pos);
		return macro null;
	}

	function attrValueExpr(attr:RailsParsedAttr):Expr {
		return switch (attr.kind) {
			case Static(value):
				macro @:pos(attr.pos) $v{value};
			case Bool:
				macro @:pos(attr.pos) true;
			case ExprValue(value):
				value;
		}
	}

	function textChildExpr(children:Array<Expr>, pos:Position):Null<Expr> {
		var parts:Array<Expr> = [];
		var staticOnly = true;
		for (child in children) {
			switch (child.expr) {
				case ECall(fn, params):
					if (isHtmlNodeCtor(fn, "Text") && params.length == 1) {
						switch (params[0].expr) {
							case EConst(CString(value, _)):
								if (StringTools.trim(value).length > 0) {
									parts.push({expr: EConst(CString(value, null)), pos: params[0].pos});
								}
							default:
								return null;
						}
					} else if (isHtmlNodeCtor(fn, "ExprText") && params.length == 1) {
						staticOnly = false;
						parts.push(params[0]);
					} else {
						return null;
					}
				default:
					return null;
			}
		}
		if (parts.length == 0) {
			return null;
		}
		if (staticOnly) {
			var out = "";
			for (part in parts) {
				switch (part.expr) {
					case EConst(CString(value, _)):
						out += value;
					default:
				}
			}
			return macro @:pos(pos) $v{StringTools.trim(out)};
		}
		var acc:Expr = null;
		for (part in parts) {
			acc = acc == null ? part : {expr: EBinop(OpAdd, acc, part), pos: pos};
		}
		return acc;
	}

	function isHtmlNodeCtor(expr:Expr, name:String):Bool {
		return switch (expr.expr) {
			case EField(_, fieldName):
				fieldName == name;
			case EMeta(_, inner) | EParenthesis(inner):
				isHtmlNodeCtor(inner, name);
			default:
				false;
		}
	}
}
#end
