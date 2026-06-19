package reflaxe.ruby.rails;

#if (macro || reflaxe_runtime)
/**
	Renders the compiler-owned Rails route IR into ordinary `config/routes.rb`
	lines. Keeping this separate from `RubyCompiler` makes route output easier to
	snapshot and evolve without turning the compiler core into a Rails router.
**/
class RailsRoutesEmitter {
	public static function renderBody(decls:Array<RailsRouteDecl>):Array<String> {
		var body:Array<String> = [];
		for (decl in decls) {
			body = body.concat(renderDecl(decl));
		}
		return body;
	}

	static function renderDecl(decl:RailsRouteDecl):Array<String> {
		return switch (decl.kind) {
			case "root":
				decl.target == null ? [] : [
					"root " + quoteRubyStringForCode(decl.target.controller + "#" + decl.target.action)
				];
			case "verb":
				if (decl.target == null) {
					[];
				} else {
					var parts = [
						"to: " + quoteRubyStringForCode(decl.target.controller + "#" + decl.target.action)
					];
					if (decl.name != "") {
						parts.push("as: " + rubySymbolLiteral(decl.name));
					}
					[decl.verb + " " + quoteRubyStringForCode(decl.path) + ", " + parts.join(", ")];
				}
			case "match":
				if (decl.target == null) {
					[];
				} else {
					var parts = [
						"to: " + quoteRubyStringForCode(decl.target.controller + "#" + decl.target.action),
						"via: [" + [for (verb in decl.verbs) rubySymbolLiteral(verb)].join(", ") + "]"
					];
					if (decl.name != "") {
						parts.push("as: " + rubySymbolLiteral(decl.name));
					}
					["match " + quoteRubyStringForCode(decl.path) + ", " + parts.join(", ")];
				}
			case "resources":
				renderResourceDecl(decl, "resources");
			case "resource":
				renderResourceDecl(decl, "resource");
			case "collection" | "member":
				if (decl.children.length == 0) {
					[];
				} else {
					renderBlock(decl.kind, renderChildren(decl.children));
				}
			case "namespace":
				renderBlock("namespace " + rubySymbolLiteral(decl.name), renderChildren(decl.children));
			case "scope":
				var parts = ["scope " + quoteRubyStringForCode(decl.path)];
				if (decl.moduleName != "") {
					parts.push("module: " + quoteRubyStringForCode(decl.moduleName));
				}
				if (decl.name != "") {
					parts.push("as: " + rubySymbolLiteral(decl.name));
				}
				renderBlock(parts.join(", "), renderChildren(decl.children));
			case "controller":
				renderBlock("controller " + quoteRubyStringForCode(decl.controller), renderChildren(decl.children));
			case "defaults":
				renderBlock("defaults " + decl.options.join(", "), renderChildren(decl.children));
			case "constraints":
				renderBlock("constraints " + decl.options.join(", "), renderChildren(decl.children));
			case "mount":
				var parts = ["mount " + decl.controller + " => " + quoteRubyStringForCode(decl.path)];
				if (decl.name != "") {
					parts.push("as: " + rubySymbolLiteral(decl.name));
				}
				[parts.join(", ")];
			case "deviseFor":
				decl.devise == null ? [] : ["devise_for " + rubySymbolLiteral(decl.devise.resource)];
			case "rawRuby":
				[decl.controller];
			case _:
				[];
		}
	}

	static function renderResourceDecl(decl:RailsRouteDecl, keyword:String):Array<String> {
		var parts = [
			keyword + " " + rubySymbolLiteral(decl.name),
			"controller: " + quoteRubyStringForCode(decl.controller)
		];
		if (decl.only.length > 0) {
			parts.push("only: [" + [for (action in decl.only) rubySymbolLiteral(action)].join(", ") + "]");
		}
		if (decl.except.length > 0) {
			parts.push("except: [" + [for (action in decl.except) rubySymbolLiteral(action)].join(", ") + "]");
		}
		if (decl.param != "") {
			parts.push("param: " + rubySymbolLiteral(decl.param));
		}
		var head = parts.join(", ");
		if (decl.children.length == 0) {
			return [head];
		}
		return renderBlock(head, renderChildren(decl.children));
	}

	static function renderChildren(children:Array<RailsRouteDecl>):Array<String> {
		var lines:Array<String> = [];
		for (child in children) {
			lines = lines.concat(renderDecl(child));
		}
		return lines;
	}

	static function renderBlock(head:String, body:Array<String>):Array<String> {
		var lines = [head + " do"];
		for (line in body) {
			lines.push("  " + line);
		}
		lines.push("end");
		return lines;
	}

	static function rubySymbolLiteral(value:String):String {
		return ~/^[A-Za-z_][A-Za-z0-9_]*$/.match(value) ? ":" + value : quoteRubyStringForCode(value);
	}

	static function quoteRubyStringForCode(value:String):String {
		var escaped = StringTools.replace(value, "\\", "\\\\");
		escaped = StringTools.replace(escaped, "\"", "\\\"");
		return "\"" + escaped + "\"";
	}
}
#end
