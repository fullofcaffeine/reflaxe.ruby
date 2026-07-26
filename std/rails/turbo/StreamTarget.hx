package rails.turbo;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.FileSystem;
import sys.io.File;
#end

/**
	Typed DOM target token for Rails Turbo stream helpers.

	The abstract still lowers to the plain Rails target string via `to String`,
	but it deliberately has no `from String`: app code must opt into
	`StreamTarget.named(...)` or shared constants so behavior-bearing DOM targets
	are searchable and cannot be replaced by casual string literals.
**/
abstract StreamTarget(String) to String {
	public inline function new(value:String) {
		this = value;
	}

	public static function named(name:String):StreamTarget {
		return new StreamTarget(name);
	}

	/**
		Build a target proven to exist in a Rails-owned ERB template.

		Use `@:railsDomTargets(...)` on RailsHx-owned HHX views instead. This
		explicit interop form names both the legacy template and its static id, so
		a missing file or renamed target becomes a compile error rather than a
		silently ignored Turbo update.
	**/
	public static macro function existing(templatePath:ExprOf<String>, target:ExprOf<String>):Expr {
		#if macro
		var path = literalString(templatePath, "StreamTarget.existing expects a literal Rails template path.");
		validateTemplatePath(path, templatePath.pos);
		var targetValue = staticString(target);
		if (targetValue == null || targetValue == "") {
			Context.error("StreamTarget.existing target must be a non-empty compile-time String token.", target.pos);
		}
		var files = existingTemplateFiles(path, templatePath.pos);
		if (files.length == 0) {
			Context.error('StreamTarget.existing could not find Rails ERB template "$path" under app/views or rails/app/views.', templatePath.pos);
		}
		var found = false;
		for (file in files) {
			if (containsStaticId(File.getContent(file), targetValue)) {
				found = true;
				break;
			}
		}
		if (!found) {
			Context.error('StreamTarget.existing could not find static id="$targetValue" in Rails ERB template "$path".', target.pos);
		}
		return macro rails.turbo.StreamTarget.named($v{targetValue});
		#else
		return macro null;
		#end
	}

	#if macro
	static function literalString(expr:Expr, message:String):String {
		return switch (expr.expr) {
			case EConst(CString(value, _)): value;
			case _:
				Context.error(message, expr.pos);
				"";
		}
	}

	static function staticString(expr:Expr):Null<String> {
		return typedStaticString(Context.typeExpr(expr));
	}

	static function typedStaticString(expr:TypedExpr):Null<String> {
		return switch (expr.expr) {
			case TConst(TString(value)):
				value;
			case TField(_, FStatic(_, fieldRef)):
				var fieldExpr = fieldRef.get().expr();
				fieldExpr == null ? null : typedStaticString(fieldExpr);
			case TMeta(_, inner) | TParenthesis(inner) | TCast(inner, _):
				typedStaticString(inner);
			case _:
				null;
		}
	}

	static function validateTemplatePath(path:String, pos:Position):Void {
		var normalized = normalize(path);
		if (normalized == ""
			|| StringTools.startsWith(normalized, "/")
			|| normalized.indexOf("..") != -1
			|| normalized.indexOf("//") != -1
			|| path.indexOf("\\") != -1) {
			Context.error("StreamTarget.existing path must be safe and relative to app/views.", pos);
		}
		for (segment in normalized.split("/")) {
			if (segment == "" || segment == "." || segment == "..") {
				Context.error("StreamTarget.existing path must not contain empty, '.', or '..' segments.", pos);
			}
		}
	}

	static function existingTemplateFiles(path:String, pos:Position):Array<String> {
		var normalized = normalizeRenderPath(path);
		var files:Array<String> = [];
		var sourceDir = haxe.io.Path.directory(Context.getPosInfos(pos).file);
		for (root in railsViewRoots(sourceDir)) {
			var slash = normalized.lastIndexOf("/");
			var dir = slash == -1 ? "" : normalized.substr(0, slash + 1);
			var name = slash == -1 ? normalized : normalized.substr(slash + 1);
			for (candidate in [
				root + "/" + normalized + ".html.erb",
				root + "/" + normalized + ".erb",
				root + "/" + dir + "_" + name + ".html.erb",
				root + "/" + dir + "_" + name + ".erb"
			]) {
				if (FileSystem.exists(candidate) && !FileSystem.isDirectory(candidate)) {
					files.push(candidate);
				}
			}
		}
		return files;
	}

	static function railsViewRoots(sourceDir:String):Array<String> {
		var roots:Array<String> = [];
		var current = normalize(sourceDir);
		while (current != "" && current != ".") {
			for (candidate in [current + "/app/views", current + "/rails/app/views"]) {
				if (FileSystem.exists(candidate) && FileSystem.isDirectory(candidate) && roots.indexOf(candidate) == -1) {
					roots.push(candidate);
				}
			}
			var parent = haxe.io.Path.directory(current);
			if (parent == current || parent == "") {
				break;
			}
			current = parent;
		}
		return roots;
	}

	static function normalizeRenderPath(path:String):String {
		var normalized = normalize(path);
		if (StringTools.endsWith(normalized, ".html.erb")) {
			normalized = normalized.substr(0, normalized.length - ".html.erb".length);
		} else if (StringTools.endsWith(normalized, ".erb")) {
			normalized = normalized.substr(0, normalized.length - ".erb".length);
		}
		var segments = normalized.split("/");
		var last = segments.pop();
		if (last != null && StringTools.startsWith(last, "_")) {
			last = last.substr(1);
		}
		if (last != null) {
			segments.push(last);
		}
		return segments.join("/");
	}

	static function normalize(path:String):String {
		return StringTools.replace(path == null ? "" : StringTools.trim(path), "\\", "/");
	}

	static function containsStaticId(source:String, target:String):Bool {
		// Comments do not produce DOM nodes, so they cannot satisfy the proof.
		var visible = ~/<%#[\s\S]*?%>/g.replace(source, "");
		visible = ~/<!--[\s\S]*?-->/g.replace(visible, "");
		var escaped = ~/[-\/\\^$*+?.()|[\]{}]/g.replace(target, "\\$&");
		return new EReg("<[A-Za-z][A-Za-z0-9:-]*\\b[^<>]*\\bid\\s*=\\s*([\"'])" + escaped + "\\1", "").match(visible);
	}
	#end
}
