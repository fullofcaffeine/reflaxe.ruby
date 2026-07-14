package reflaxe.ruby.rails;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Expr.Position;

private typedef RouteManifestPayload = {
	final version:Int;
	final source:String;
	final output:String;
	final routeClass:String;
	final declarations:Array<RouteManifestDeclPayload>;
}

private typedef RouteManifestDeclPayload = {
	final kind:String;
	final position:String;
	@:optional var extensionJson:String;
	@:optional var target:String;
	@:optional var verb:String;
	@:optional var verbs:Array<String>;
	@:optional var path:String;
	@:optional var name:String;
	@:optional var controller:String;
	@:optional var moduleName:String;
	@:optional var only:Array<String>;
	@:optional var except:Array<String>;
	@:optional var param:String;
	@:optional var options:Array<String>;
	@:optional var opaque:Bool;
	@:optional var lineSha256:String;
	@:optional var children:Array<RouteManifestDeclPayload>;
}

/**
	Serializes Haxe-owned route declarations into a checked manifest consumed by
	future route parity tooling. This is not Rails' route-helper oracle; Rails
	still owns helper names after `rails routes` runs.
**/
class RailsRouteManifest {
	public static function render(source:String, output:String, routeClass:String, decls:Array<RailsRouteDecl>):String {
		var payload:RouteManifestPayload = {
			version: 1,
			source: source,
			output: output,
			routeClass: routeClass,
			declarations: [for (decl in decls) routeDecl(decl)]
		};
		return manifestJson(payload) + "\n";
	}

	static function routeDecl(decl:RailsRouteDecl):RouteManifestDeclPayload {
		var out:RouteManifestDeclPayload = {
			kind: decl.kind,
			position: positionString(decl.pos)
		};
		if (decl.target != null) {
			out.target = decl.target.controller + "#" + decl.target.action;
		}
		if (decl.extension != null) {
			out.extensionJson = extensionManifestJson(decl.extension.manifestJson, decl.pos);
		}
		if (decl.verb != "") {
			out.verb = decl.verb;
		}
		if (decl.verbs.length > 0) {
			out.verbs = decl.verbs;
		}
		if (decl.path != "") {
			out.path = decl.path;
		}
		if (decl.name != "") {
			out.name = decl.name;
		}
		if (decl.controller != "" && decl.kind != "rawRuby") {
			out.controller = decl.controller;
		}
		if (decl.moduleName != "") {
			out.moduleName = decl.moduleName;
		}
		if (decl.only.length > 0) {
			out.only = decl.only;
		}
		if (decl.except.length > 0) {
			out.except = decl.except;
		}
		if (decl.param != "") {
			out.param = decl.param;
		}
		if (decl.options.length > 0) {
			out.options = decl.options;
		}
		if (decl.kind == "rawRuby") {
			out.opaque = true;
			out.lineSha256 = haxe.crypto.Sha256.encode(decl.controller);
		}
		if (decl.children.length > 0) {
			out.children = [for (child in decl.children) routeDecl(child)];
		}
		return out;
	}

	// The JSON schema uses Rails-facing keys such as `class` and variant-shaped
	// `options`, so keep Haxe construction typed and serialize those keys here.
	static function manifestJson(payload:RouteManifestPayload):String {
		var fields = [
			jsonField("output", stringJson(payload.output), 2),
			jsonField("declarations", arrayJson([for (decl in payload.declarations) routeDeclJson(decl, 4)], 2), 2),
			jsonField("source", stringJson(payload.source), 2),
			jsonField("version", intJson(payload.version), 2),
			jsonField("class", stringJson(payload.routeClass), 2)
		];
		return objectJson(fields, 0);
	}

	static function routeDeclJson(decl:RouteManifestDeclPayload, indent:Int):String {
		if (decl.extensionJson != null) {
			return indentMultilineJson(decl.extensionJson, indent);
		}
		var fieldIndent = indent + 2;
		var fields:Array<String> = [];
		if (decl.name != null) {
			fields.push(jsonField("name", stringJson(decl.name), fieldIndent));
		}
		if (decl.options != null) {
			fields.push(jsonField("options", stringArrayJson(decl.options, fieldIndent), fieldIndent));
		}
		if (decl.only != null) {
			fields.push(jsonField("only", stringArrayJson(decl.only, fieldIndent), fieldIndent));
		}
		if (decl.verbs != null) {
			fields.push(jsonField("verbs", stringArrayJson(decl.verbs, fieldIndent), fieldIndent));
		}
		if (decl.moduleName != null) {
			fields.push(jsonField("moduleName", stringJson(decl.moduleName), fieldIndent));
		}
		fields.push(jsonField("position", stringJson(decl.position), fieldIndent));
		if (decl.target != null) {
			fields.push(jsonField("target", stringJson(decl.target), fieldIndent));
		}
		if (decl.except != null) {
			fields.push(jsonField("except", stringArrayJson(decl.except, fieldIndent), fieldIndent));
		}
		if (decl.path != null) {
			fields.push(jsonField("path", stringJson(decl.path), fieldIndent));
		}
		if (decl.controller != null) {
			fields.push(jsonField("controller", stringJson(decl.controller), fieldIndent));
		}
		fields.push(jsonField("kind", stringJson(decl.kind), fieldIndent));
		if (decl.verb != null) {
			fields.push(jsonField("verb", stringJson(decl.verb), fieldIndent));
		}
		if (decl.children != null) {
			fields.push(jsonField("children", arrayJson([for (child in decl.children) routeDeclJson(child, fieldIndent + 2)], fieldIndent), fieldIndent));
		}
		if (decl.param != null) {
			fields.push(jsonField("param", stringJson(decl.param), fieldIndent));
		}
		if (decl.opaque != null) {
			fields.push(jsonField("opaque", boolJson(decl.opaque), fieldIndent));
		}
		if (decl.lineSha256 != null) {
			fields.push(jsonField("lineSha256", stringJson(decl.lineSha256), fieldIndent));
		}
		return objectJson(fields, indent);
	}

	static function extensionManifestJson(manifestJson:String, pos:Position):String {
		var marker = "__railshx_position__";
		if (manifestJson.indexOf(marker) == -1 || manifestJson.indexOf(marker) != manifestJson.lastIndexOf(marker)) {
			Context.error("Route extension manifest must contain exactly one RailsHx position marker.", pos);
		}
		var encodedPosition = haxe.Json.stringify(positionString(pos));
		var withPosition = StringTools.replace(manifestJson, marker, encodedPosition.substr(1, encodedPosition.length - 2));
		try {
			// Extension manifests are an explicit structured interop boundary. Parse
			// the opaque object only to reject malformed/non-object payloads; the
			// companion owns its versioned fields and downstream interpretation.
			var parsed:Dynamic = haxe.Json.parse(withPosition);
			if (parsed == null || !Reflect.isObject(parsed) || Std.isOfType(parsed, Array)) {
				Context.error("Route extension manifest must be a JSON object.", pos);
			}
			var kind = Reflect.field(parsed, "kind");
			if (!Std.isOfType(kind, String) || Std.string(kind).length == 0) {
				Context.error('Route extension manifest requires a non-empty "kind" String.', pos);
			}
			return haxe.Json.stringify(parsed, null, "  ");
		} catch (error:Dynamic) {
			Context.error("Route extension manifest is invalid JSON: " + Std.string(error), pos);
			return "{}";
		}
	}

	static function indentMultilineJson(value:String, indent:Int):String {
		var prefix = indentString(indent);
		return value.split("\n").join("\n" + prefix);
	}

	static function stringArrayJson(values:Array<String>, indent:Int):String {
		return arrayJson([for (value in values) stringJson(value)], indent);
	}

	static function arrayJson(values:Array<String>, indent:Int):String {
		if (values.length == 0) {
			return "[]";
		}
		var itemIndent = indent + 2;
		return "[\n" + [for (value in values) indentString(itemIndent) + value].join(",\n") + "\n" + indentString(indent) + "]";
	}

	static function objectJson(fields:Array<String>, indent:Int):String {
		if (fields.length == 0) {
			return "{}";
		}
		return "{\n" + fields.join(",\n") + "\n" + indentString(indent) + "}";
	}

	static function jsonField(name:String, valueJson:String, indent:Int):String {
		return indentString(indent) + stringJson(name) + ": " + valueJson;
	}

	static function stringJson(value:String):String {
		return haxe.Json.stringify(value);
	}

	static function intJson(value:Int):String {
		return Std.string(value);
	}

	static function boolJson(value:Bool):String {
		return value ? "true" : "false";
	}

	static function indentString(width:Int):String {
		return StringTools.lpad("", " ", width);
	}

	static function positionString(pos:Position):String {
		var info = Context.getPosInfos(pos);
		return stablePositionFile(info.file) + ":" + info.min + "-" + info.max;
	}

	static function stablePositionFile(file:String):String {
		// Route manifests are committed/snapshotted review artifacts. Haxe macro
		// positions often arrive as absolute local paths, so strip the compiler
		// working directory and keep a stable repo-relative source hint.
		var normalizedFile = StringTools.replace(file, "\\", "/");
		var cwd = StringTools.replace(Sys.getCwd(), "\\", "/");
		if (StringTools.endsWith(cwd, "/")) {
			cwd = cwd.substr(0, cwd.length - 1);
		}
		var prefix = cwd + "/";
		if (StringTools.startsWith(normalizedFile, prefix)) {
			return normalizedFile.substr(prefix.length);
		}
		return normalizedFile;
	}
}
#end
