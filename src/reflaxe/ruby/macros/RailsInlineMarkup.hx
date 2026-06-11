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
		return cls.meta.has(":railsTemplate") || cls.meta.has("railsTemplate") || cls.meta.has(":rails_hxx_inline_markup")
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
			var ok = (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || (c >= "0" && c <= "9") || c == "_" || c == "-"
				|| c == ":" || c == ".";
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
		return macro @:pos(pos) rails.action_view.HtmlNode.For($items, ${{expr: EFunction(FArrow, fn), pos: pos}});
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
			return {name: name, kind: Bool, expr: macro @:pos(pos) rails.action_view.HtmlAttr.Bool($v{name}), pos: pos};
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
			return {name: name, kind: Static(value), expr: macro @:pos(pos2) rails.action_view.HtmlAttr.Static($v{name}, $v{value}), pos: pos2};
		}
		if (startsWith("${") || startsWith("{")) {
			var expr = parseExprInBraces();
			var pos3 = makeSubPos(attrStart, i);
			return {name: name, kind: ExprValue(expr), expr: macro @:pos(pos3) rails.action_view.HtmlAttr.Expr($v{name}, $expr), pos: pos3};
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
				macro @:pos(pos) rails.action_view.HtmlNode.FormLabel($labelName, $text);
			case "text_field":
				var textFieldName = requireAttrValue(attrs, "name", pos);
				var textFieldAttrs = attrsExcept(attrs, ["name"]);
				macro @:pos(pos) rails.action_view.HtmlNode.FormTextField($textFieldName, ${mkArray(textFieldAttrs.map(mkAttr), pos)});
			case "text_area":
				var textAreaName = requireAttrValue(attrs, "name", pos);
				var textAreaAttrs = attrsExcept(attrs, ["name"]);
				macro @:pos(pos) rails.action_view.HtmlNode.FormTextArea($textAreaName, ${mkArray(textAreaAttrs.map(mkAttr), pos)});
			case "check_box":
				var checkBoxName = requireAttrValue(attrs, "name", pos);
				var checkBoxAttrs = attrsExcept(attrs, ["name"]);
				macro @:pos(pos) rails.action_view.HtmlNode.FormCheckBox($checkBoxName, ${mkArray(checkBoxAttrs.map(mkAttr), pos)});
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
			case "partial":
				var template = requireAttrValue(attrs, "template", pos);
				var locals = requireAttrValue(attrs, "locals", pos);
				macro @:pos(pos) rails.action_view.HtmlNode.Partial($template, $locals);
			case "component":
				var template = requireAttrValue(attrs, "template", pos);
				var locals = requireAttrValue(attrs, "locals", pos);
				var slot = requireAttrValue(attrs, "slot", pos);
				rejectAttrs(name, attrsExcept(attrs, ["template", "locals", "slot"]), pos);
				macro @:pos(pos) rails.action_view.HtmlNode.Component($template, $locals, $slot, ${mkArray(children, pos)});
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

	function rejectAttrs(tagName:String, attrs:Array<RailsParsedAttr>, pos:Position):Void {
		if (attrs.length > 0) {
			Context.error('Rails HHX <' + tagName + '> does not accept attributes yet.', pos);
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
