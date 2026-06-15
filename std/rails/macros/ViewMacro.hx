package rails.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.ruby.naming.RubyNaming;
import sys.FileSystem;
#else
import haxe.macro.Expr;
#end

class ViewMacro {
	public static macro function renderTemplate<TLocals>(controller:Expr, template:ExprOf<rails.action_view.Template<TLocals>>, locals:ExprOf<TLocals>):Expr {
		#if macro
		var templatePath = extractTemplatePath(template);
		validateLocalsObject(locals);
		validateLocalsType(template, locals);
		var railsLocals = railsLocalsObject(locals);
		return macro $controller.render({template: $v{templatePath}, locals: $railsLocals});
		#else
		return macro null;
		#end
	}

	public static macro function renderTemplateWithLayout<TLocals>(controller:Expr, template:ExprOf<rails.action_view.Template<TLocals>>, locals:ExprOf<TLocals>,
			layout:ExprOf<rails.action_view.Layout>):Expr {
		#if macro
		var templatePath = extractTemplatePath(template);
		var layoutPath = extractLayoutPath(layout);
		validateLocalsObject(locals);
		validateLocalsType(template, locals);
		var railsLocals = railsLocalsObject(locals);
		return macro $controller.render({template: $v{templatePath}, locals: $railsLocals, layout: $v{layoutPath}});
		#else
		return macro null;
		#end
	}

	#if macro
	static function extractTemplatePath(template:Expr):String {
		return switch (unwrapTypedMarker(template).expr) {
			case ECall(callee, [path]):
				var calleeName = templateCalleeName(callee);
				switch (calleeName) {
					case "named", "external":
						var value = extractString(path, "Template.named/external expects a string literal path.");
						validateTemplatePath(value, path.pos, "Template." + calleeName);
						normalizeRenderPath(value);
					case "of":
						ownedTemplatePath(path, false);
					case "existing":
						var value = extractString(path, "Template.existing expects a string literal path.");
						validateTemplatePath(value, path.pos, "Template.existing");
						validateExternalTemplateExists(value, path.pos);
						normalizeRenderPath(value);
					case _:
						throw "ViewMacro.renderTemplate expects Template.of(...), Template.named(...), Template.existing(...), or Template.external(...) as the template argument.";
				}
			case _:
				throw "ViewMacro.renderTemplate expects Template.of(...), Template.named(...), Template.existing(...), or Template.external(...) as the template argument.";
		}
	}

	static function extractLayoutPath(layout:Expr):String {
		return switch (unwrapTypedMarker(layout).expr) {
			case ECall(callee, [view]) if (templateCalleeName(callee) == "layout"):
				ownedTemplatePath(view, true);
			case ECall(callee, [path]) if (templateCalleeName(callee) == "named" && layoutCalleeOwnerName(callee) == "Layout"):
				var value = extractString(path, "Layout.named expects a string literal path.");
				validateTemplatePath(value, path.pos, "Layout.named");
				normalizeLayoutPath(value);
			case _:
				throw "ViewMacro.renderTemplateWithLayout layout expects Template.layout(ViewClass) or Layout.named(\"path\").";
		}
	}

	static function unwrapTypedMarker(expr:Expr):Expr {
		return switch (expr.expr) {
			case ECheckType(inner, _): unwrapTypedMarker(inner);
			case EParenthesis(inner): unwrapTypedMarker(inner);
			case _: expr;
		}
	}

	static function templateCalleeName(callee:Expr):Null<String> {
		return switch (callee.expr) {
			case EField(_, name): name;
			case _: null;
		}
	}

	static function layoutCalleeOwnerName(callee:Expr):Null<String> {
		return switch (callee.expr) {
			case EField(owner, _):
				switch (owner.expr) {
					case EConst(CIdent(name)): name;
					case EField(_, name): name;
					case _: null;
				}
			case _: null;
		}
	}

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

	static function validateLocalsObject(locals:Expr):Void {
		switch (locals.expr) {
			case EObjectDecl(fields):
				if (fields.length == 0) {
					throw "ViewMacro.renderTemplate locals must include at least one named local.";
				}
			case _:
				throw "ViewMacro.renderTemplate locals must be an object literal so Rails local names are explicit.";
		}
	}

	static function validateLocalsType(template:Expr, locals:Expr):Void {
		var expected = switch (Context.typeof(template)) {
			case TInst(classRef, [localsType]) if (classRef.get().pack.join(".") == "rails.action_view" && classRef.get().name == "Template"):
				localsType;
			case _:
				Context.error("ViewMacro.renderTemplate template argument must be rails.action_view.Template<TLocals>.", template.pos);
				return;
		}
		var actual = Context.typeof(locals);
		if (!Context.unify(actual, expected)) {
			Context.error("ViewMacro.renderTemplate locals do not match the Template<TLocals> contract.", locals.pos);
		}
	}

	static function railsLocalsObject(locals:Expr):Expr {
		return switch (locals.expr) {
			case EObjectDecl(fields):
				{
					expr: EObjectDecl([
						for (field in fields) {
							field: RubyNaming.toLocalName(field.field),
							expr: field.expr,
							quotes: field.quotes
						}
					]),
					pos: locals.pos
				};
			case _:
				locals;
		}
	}

	static function extractString(expr:Expr, message:String):String {
		return switch (expr.expr) {
			case EConst(CString(value, _)): value;
			case _: throw message;
		}
	}

	static function metaStringParam(meta:Null<MetaAccess>, name:String, index:Int):Null<String> {
		if (meta == null) {
			return null;
		}
		var entries = meta.extract(name);
		if (entries.length == 0 || entries[0].params == null || entries[0].params.length <= index) {
			return null;
		}
		return switch (entries[0].params[index].expr) {
			case EConst(CString(value, _)): value;
			case _: null;
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
			|| path.indexOf("\\") != -1) {
			Context.error(context + " path must be a safe Rails template path relative to app/views.", pos);
		}
		for (segment in normalized.split("/")) {
			if (segment == "" || segment == "." || segment == "..") {
				Context.error(context + " path must not contain empty, '.', or '..' segments.", pos);
			}
		}
	}

	static function validateExternalTemplateExists(path:String, pos:Position):Void {
		for (candidate in externalTemplateCandidates(path, pos)) {
			if (FileSystem.exists(candidate)) {
				return;
			}
		}
		Context.error("Template.existing could not find a Rails ERB template for `" + path + "` under app/views or rails/app/views.", pos);
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
