package reflaxe.ruby.rails;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Expr.Position;

/**
	Serializes Haxe-owned route declarations into a checked manifest consumed by
	future route parity tooling. This is not Rails' route-helper oracle; Rails
	still owns helper names after `rails routes` runs.
**/
class RailsRouteManifest {
	public static function render(source:String, output:String, routeClass:String, decls:Array<RailsRouteDecl>):String {
		var payload:Dynamic = {};
		Reflect.setField(payload, "version", 1);
		Reflect.setField(payload, "source", source);
		Reflect.setField(payload, "output", output);
		Reflect.setField(payload, "class", routeClass);
		Reflect.setField(payload, "declarations", [for (decl in decls) routeDecl(decl)]);
		return haxe.Json.stringify(payload, null, "  ") + "\n";
	}

	static function routeDecl(decl:RailsRouteDecl):Dynamic {
		var out:Dynamic = {};
		Reflect.setField(out, "kind", decl.kind);
		Reflect.setField(out, "position", positionString(decl.pos));
		if (decl.target != null) {
			Reflect.setField(out, "target", decl.target.controller + "#" + decl.target.action);
		}
		if (decl.verb != "") {
			Reflect.setField(out, "verb", decl.verb);
		}
		if (decl.verbs.length > 0) {
			Reflect.setField(out, "verbs", decl.verbs);
		}
		if (decl.path != "") {
			Reflect.setField(out, "path", decl.path);
		}
		if (decl.name != "") {
			Reflect.setField(out, "name", decl.name);
		}
		if (decl.controller != "" && decl.kind != "rawRuby") {
			Reflect.setField(out, "controller", decl.controller);
		}
		if (decl.moduleName != "") {
			Reflect.setField(out, "moduleName", decl.moduleName);
		}
		if (decl.only.length > 0) {
			Reflect.setField(out, "only", decl.only);
		}
		if (decl.except.length > 0) {
			Reflect.setField(out, "except", decl.except);
		}
		if (decl.param != "") {
			Reflect.setField(out, "param", decl.param);
		}
		if (decl.options.length > 0) {
			Reflect.setField(out, "options", decl.options);
		}
		if (decl.kind == "rawRuby") {
			Reflect.setField(out, "opaque", true);
			Reflect.setField(out, "lineSha256", haxe.crypto.Sha256.encode(decl.controller));
		}
		if (decl.children.length > 0) {
			Reflect.setField(out, "children", [for (child in decl.children) routeDecl(child)]);
		}
		return out;
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
