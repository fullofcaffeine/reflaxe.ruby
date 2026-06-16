package rails.action_view;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.FileSystem;
#end

class Component<TLocals> {
	public final templatePath:String;
	public final slotName:String;
	public final isExternal:Bool;

	public function new(path:String, slotName:String, ?isExternal:Bool = false) {
		this.templatePath = path;
		this.slotName = slotName;
		this.isExternal = isExternal;
	}

	public static function named<TLocals>(path:String, slotName:String):Component<TLocals> {
		return new Component(path, slotName);
	}

	public static function external<TLocals>(path:String, slotName:String):Component<TLocals> {
		return new Component(path, slotName, true);
	}

	/**
		Build a component reference from a RailsHx-owned HHX partial.

		The component still lowers to Rails-native `capture` plus
		`render partial:`. This token only centralizes the reusable component's
		template path and default slot name so call sites avoid repeated strings.
	**/
	public static macro function of(view:Expr, slotName:ExprOf<String>):Expr {
		#if macro
		var path = ownedTemplatePath(view);
		var slot = extractString(slotName, "Component.of expects a string literal slot name.");
		validateComponentSlotName(slot, slotName.pos, "Component.of");
		return macro rails.action_view.Component.named($v{path}, $v{slot});
		#else
		return macro null;
		#end
	}

	/**
		Compile-time checked reference to an existing Rails-owned component
		partial.
	**/
	public static macro function existing<TLocals>(path:ExprOf<String>, slotName:ExprOf<String>):Expr {
		#if macro
		var value = extractString(path, "Component.existing expects a string literal path.");
		var slot = extractString(slotName, "Component.existing expects a string literal slot name.");
		validateTemplatePath(value, path.pos, "Component.existing");
		validateComponentSlotName(slot, slotName.pos, "Component.existing");
		validateExternalTemplateExists(value, path.pos);
		return macro rails.action_view.Component.external($v{normalizeRenderPath(value)}, $v{slot});
		#else
		return macro null;
		#end
	}

	#if macro
	static function ownedTemplatePath(view:Expr):String {
		var classType = switch (Context.typeExpr(view).expr) {
			case TTypeExpr(TClassDecl(classRef)):
				classRef.get();
			case _:
				Context.error("Component.of expects a RailsHx view class reference.", view.pos);
				return "";
		}
		var path = metaStringParam(classType.meta, ":railsTemplate", 0);
		if (path == null) {
			Context.error("Component.of expects a class annotated with @:railsTemplate(\"path\").", view.pos);
			return "";
		}
		validateTemplatePath(path, view.pos, "@:railsTemplate");
		return normalizeRenderPath(path);
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
			case _:
				var typedValue = typedStaticString(Context.typeExpr(expr));
				if (typedValue != null) {
					typedValue;
				} else {
					Context.error(message, expr.pos);
					"";
				}
		}
	}

	static function extractTypedStaticString(expr:Expr):Null<String> {
		return switch (Context.typeExpr(expr).expr) {
			case TField(_, FStatic(_, fieldRef)):
				var fieldExpr = fieldRef.get().expr();
				fieldExpr == null ? null : typedStaticString(fieldExpr);
			case _:
				null;
		}
	}

	static function typedStaticString(expr:TypedExpr):Null<String> {
		return switch (expr.expr) {
			case TConst(TString(value)):
				value;
			case TMeta(_, inner) | TParenthesis(inner) | TCast(inner, _):
				typedStaticString(inner);
			case _:
				null;
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

	static function validateTemplatePath(path:String, pos:Position, context:String):Void {
		var normalized = normalizePathSlashes(path);
		if (normalized == ""
			|| StringTools.startsWith(normalized, "/")
			|| normalized.indexOf("..") != -1
			|| normalized.indexOf("//") != -1
			|| path.indexOf("\\") != -1) {
			Context.error(context + " path must be a safe Rails template path relative to app/views.", pos);
		}
		for (segment in normalized.split("/")) {
			if (segment == "" || segment == "." || segment == "..") {
				Context.error(context + " path must not contain empty, '.', or '..' segments.", pos);
			}
		}
	}

	static function validateComponentSlotName(slotName:String, pos:Position, context:String):Void {
		if (!~/^[A-Za-z_][A-Za-z0-9_]*$/.match(slotName)) {
			Context.error(context + " slot name must be a safe Haxe/Ruby local identifier.", pos);
		}
	}

	static function validateExternalTemplateExists(path:String, pos:Position):Void {
		for (candidate in externalTemplateCandidates(path, pos)) {
			if (FileSystem.exists(candidate)) {
				return;
			}
		}
		Context.error("Component.existing could not find a Rails ERB template for `" + path + "` under app/views or rails/app/views.", pos);
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
