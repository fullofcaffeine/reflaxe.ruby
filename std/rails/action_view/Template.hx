package rails.action_view;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.FileSystem;
#end

class Template<TLocals> {
	public final templatePath:String;
	public final isExternal:Bool;

	public function new(path:String, ?isExternal:Bool = false) {
		this.templatePath = path;
		this.isExternal = isExternal;
	}

	public static function named<TLocals>(path:String):Template<TLocals> {
		return new Template(path);
	}

	public static function external<TLocals>(path:String):Template<TLocals> {
		return new Template(path, true);
	}

	/**
		Build a template reference from a RailsHx-owned view class.

		Prefer this over `Template.named("...")` for HHX templates: renaming or
		deleting the Haxe view class now fails at compile time instead of becoming a
		stale Rails render string.
	**/
	public static macro function of(view:Expr):Expr {
		#if macro
		var path = ownedTemplatePath(view, false);
		return macro rails.action_view.Template.named($v{path});
		#else
		return macro null;
		#end
	}

	/**
		Build a Rails layout name from a RailsHx-owned layout view class.
	**/
	public static macro function layout(view:Expr):ExprOf<Layout> {
		#if macro
		var path = ownedTemplatePath(view, true);
		return macro rails.action_view.Layout.named($v{path});
		#else
		return macro null;
		#end
	}

	/**
		Compile-time checked reference to an existing Rails-owned ERB template.

		This is the preferred interop seam for legacy Rails partials/templates.
	**/
	public static macro function existing<TLocals>(path:ExprOf<String>):Expr {
		#if macro
		var value = extractString(path, "Template.existing expects a string literal path.");
		validateTemplatePath(value, path.pos, "Template.existing");
		validateExternalTemplateExists(value, path.pos);
		return macro rails.action_view.Template.external($v{normalizeRenderPath(value)});
		#else
		return macro null;
		#end
	}

	#if macro
	static function ownedTemplatePath(view:Expr, layoutMode:Bool):String {
		var classType = switch (Context.typeExpr(view).expr) {
			case TTypeExpr(TClassDecl(classRef)):
				classRef.get();
			case _:
				Context.error("Template.of/layout expects a RailsHx view class reference.", view.pos);
				return "";
		}
		var path = metaStringParam(classType.meta, ":railsTemplate", 0);
		if (path == null) {
			Context.error("Template.of/layout expects a class annotated with @:railsTemplate(\"path\").", view.pos);
			return "";
		}
		validateTemplatePath(path, view.pos, "@:railsTemplate");
		return layoutMode ? normalizeLayoutPath(path) : normalizeRenderPath(path);
	}

	static function metaStringParam(meta:Null<MetaAccess>, name:String, index:Int):Null<String> {
		if (meta == null) {
			return null;
		}
		var entries = meta.extract(name);
		if (entries.length == 0 || entries[0].params == null || entries[0].params.length <= index) {
			return null;
		}
		return extractString(entries[0].params[index], '@:railsTemplate expects a string literal path.');
	}

	static function extractString(expr:Expr, message:String):String {
		return switch (expr.expr) {
			case EConst(CString(value, _)): value;
			case _: Context.error(message, expr.pos); "";
		}
	}

	static function normalizeRenderPath(path:String):String {
		var normalized = normalizePathSlashes(path);
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

	static function normalizeLayoutPath(path:String):String {
		var normalized = normalizeRenderPath(path);
		return StringTools.startsWith(normalized, "layouts/") ? normalized.substr("layouts/".length) : normalized;
	}

	static function validateTemplatePath(path:String, pos:Position, context:String):Void {
		var normalized = normalizePathSlashes(path);
		if (normalized == "" || StringTools.startsWith(normalized, "/") || normalized.indexOf("..") != -1 || normalized.indexOf("//") != -1
			|| normalized.indexOf("\\") != -1) {
			Context.error(context + " path must be a safe Rails template path relative to app/views.", pos);
		}
		for (segment in normalized.split("/")) {
			if (segment == "" || segment == "." || segment == "..") {
				Context.error(context + " path must not contain empty, '.', or '..' segments.", pos);
			}
		}
	}

	static function validateExternalTemplateExists(path:String, pos:Position):Void {
		var found = false;
		for (candidate in externalTemplateCandidates(path, pos)) {
			if (FileSystem.exists(candidate)) {
				found = true;
				break;
			}
		}
		if (!found) {
			Context.error("Template.existing could not find a Rails ERB template for `" + path + "` under app/views or rails/app/views.", pos);
		}
	}

	static function externalTemplateCandidates(path:String, pos:Position):Array<String> {
		var candidates:Array<String> = [];
		var normalized = normalizeRenderPath(path);
		var sourceDir = haxe.io.Path.directory(Context.getPosInfos(pos).file);
		for (root in railsViewRoots(sourceDir)) {
			var base = root + "/" + normalized;
			candidates.push(base + ".html.erb");
			candidates.push(base + ".erb");
			var slash = normalized.lastIndexOf("/");
			var dir = slash == -1 ? "" : normalized.substr(0, slash + 1);
			var name = slash == -1 ? normalized : normalized.substr(slash + 1);
			candidates.push(root + "/" + dir + "_" + name + ".html.erb");
			candidates.push(root + "/" + dir + "_" + name + ".erb");
		}
		return candidates;
	}

	static function railsViewRoots(sourceDir:String):Array<String> {
		var roots:Array<String> = [];
		var current = normalizePathSlashes(sourceDir);
		while (current != "" && current != ".") {
			var appViews = current + "/app/views";
			var railsAppViews = current + "/rails/app/views";
			if (FileSystem.exists(appViews) && FileSystem.isDirectory(appViews)) {
				roots.push(appViews);
			}
			if (FileSystem.exists(railsAppViews) && FileSystem.isDirectory(railsAppViews)) {
				roots.push(railsAppViews);
			}
			var parent = haxe.io.Path.directory(current);
			if (parent == current || parent == "") {
				break;
			}
			current = parent;
		}
		return roots;
	}

	static function normalizePathSlashes(path:String):String {
		return StringTools.replace(path == null ? "" : StringTools.trim(path), "\\", "/");
	}
	#end
}
