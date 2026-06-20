package rails.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import reflaxe.ruby.naming.RubyNaming;
import sys.FileSystem;
#else
import haxe.macro.Expr;
#end

class MailerMacro {
	#if macro
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var local = Context.getLocalClass();
		if (local == null) {
			return fields;
		}
		var classType = local.get();
		var entries = classType.meta.extract(":railsMailerParams");
		if (entries.length == 0) {
			return fields;
		}
		if (entries.length > 1) {
			Context.error("@:railsMailerParams may be declared only once per mailer.", entries[1].pos);
			return fields;
		}
		var entry = entries[0];
		if (entry.params == null || entry.params.length != 1) {
			Context.error("@:railsMailerParams expects one params typedef, for example @:railsMailerParams(WelcomeMailerParams).", entry.pos);
			return fields;
		}

		var paramsType = resolveParamsTypedef(entry.params[0], classType);
		var paramsComplex = paramsComplexType(entry.params[0], classType);
		var selfType:ComplexType = TPath({
			pack: classType.pack,
			name: classType.name,
			params: [],
			sub: null
		});

		// This build macro turns one typed params typedef into the two Rails-facing
		// conveniences RailsHx users need: a checked `.with(...)` wrapper and
		// typed param tokens. Both are compiler facades; generated Ruby remains
		// ordinary ActionMailer `.with(key: value)` and `params[:key]` code.
		addWithParamsStub(fields, paramsComplex, selfType, classType.pos);
		addParamTokenField(fields, paramsType, classType.pos);
		return fields;
	}
	#end

	public static macro function mailHtml<TLocals>(mailer:Expr, options:ExprOf<rails.action_mailer.MailOptions>,
			template:ExprOf<rails.action_view.Template<TLocals>>, locals:ExprOf<TLocals>):Expr {
		#if macro
		var templatePath = extractTemplatePath(template);
		validateLocalsObject(locals);
		validateLocalsType(template, locals, "MailerMacro.mailHtml");
		var railsLocals = railsLocalsObject(locals);
		return macro $mailer.mail($options, function(format) {
			format.html(function() {
				$mailer.render({template: $v{templatePath}, locals: $railsLocals});
			});
		});
		#else
		return macro null;
		#end
	}

	public static macro function mailText<TLocals>(mailer:Expr, options:ExprOf<rails.action_mailer.MailOptions>,
			template:ExprOf<rails.action_view.Template<TLocals>>, locals:ExprOf<TLocals>):Expr {
		#if macro
		var templatePath = extractTemplatePath(template);
		validateLocalsObject(locals);
		validateLocalsType(template, locals, "MailerMacro.mailText");
		var railsLocals = railsLocalsObject(locals);
		return macro $mailer.mail($options, function(format) {
			format.text(function() {
				$mailer.render({template: $v{templatePath}, locals: $railsLocals});
			});
		});
		#else
		return macro null;
		#end
	}

	public static macro function mailMultipart<THtmlLocals, TTextLocals>(mailer:Expr, options:ExprOf<rails.action_mailer.MailOptions>,
			htmlTemplate:ExprOf<rails.action_view.Template<THtmlLocals>>, htmlLocals:ExprOf<THtmlLocals>,
			textTemplate:ExprOf<rails.action_view.Template<TTextLocals>>, textLocals:ExprOf<TTextLocals>):Expr {
		#if macro
		var htmlTemplatePath = extractTemplatePath(htmlTemplate);
		var textTemplatePath = extractTemplatePath(textTemplate);
		validateLocalsObject(htmlLocals);
		validateLocalsObject(textLocals);
		validateLocalsType(htmlTemplate, htmlLocals, "MailerMacro.mailMultipart html");
		validateLocalsType(textTemplate, textLocals, "MailerMacro.mailMultipart text");
		var railsHtmlLocals = railsLocalsObject(htmlLocals);
		var railsTextLocals = railsLocalsObject(textLocals);
		return macro $mailer.mail($options, function(format) {
			format.html(function() {
				$mailer.render({template: $v{htmlTemplatePath}, locals: $railsHtmlLocals});
			});
			format.text(function() {
				$mailer.render({template: $v{textTemplatePath}, locals: $railsTextLocals});
			});
		});
		#else
		return macro null;
		#end
	}

	#if macro
	static function addWithParamsStub(fields:Array<Field>, paramsType:ComplexType, selfType:ComplexType, pos:Position):Void {
		if (hasField(fields, "withParams")) {
			return;
		}
		fields.push({
			name: "withParams",
			access: [APublic, AStatic],
			kind: FFun({
				args: [{name: "params", type: paramsType}],
				ret: selfType,
				expr: macro return cast null
			}),
			meta: [
				{name: ":native", params: [macro "with"], pos: pos},
				{name: ":rubyKwargs", params: [], pos: pos},
				{name: ":rubyExternStub", params: [], pos: pos}
			],
			pos: pos
		});
	}

	static function addParamTokenField(fields:Array<Field>, paramsType:Type, pos:Position):Void {
		if (hasField(fields, "p")) {
			return;
		}
		var paramsFields = typedParamsFields(paramsType, pos);
		if (paramsFields.length == 0) {
			Context.error("@:railsMailerParams typedef must declare at least one params field.", pos);
			return;
		}
		var objectFields:Array<Field> = [];
		var values:Array<ObjectField> = [];
		for (field in paramsFields) {
			var valueType = TypeTools.toComplexType(field.type);
			objectFields.push({
				name: field.name,
				access: [],
				kind: FVar(TPath({
					pack: ["rails", "action_mailer"],
					name: "MailParam",
					params: [TPType(valueType)],
					sub: null
				}), null),
				pos: pos
			});
			values.push({
				field: field.name,
				expr: macro rails.action_mailer.MailParam.named($v{RubyNaming.toLocalName(field.name)}),
				quotes: null
			});
		}
		fields.push({
			name: "p",
			access: [APublic, AStatic, AFinal],
			kind: FVar(TAnonymous(objectFields), {expr: EObjectDecl(values), pos: pos}),
			meta: [{name: ":rubyExternStub", params: [], pos: pos}],
			pos: pos
		});
	}

	static function hasField(fields:Array<Field>, name:String):Bool {
		for (field in fields) {
			if (field.name == name) {
				return true;
			}
		}
		return false;
	}

	static function typedParamsFields(paramsType:Type, pos:Position):Array<ClassField> {
		return switch (TypeTools.follow(paramsType)) {
			case TAnonymous(anonRef):
				anonRef.get().fields;
			case _:
				Context.error("@:railsMailerParams expects a typedef or anonymous object type.", pos);
				[];
		}
	}

	static function resolveParamsTypedef(expr:Expr, owner:ClassType):Type {
		var candidates = typeNameCandidates(expr, owner);
		for (candidate in candidates) {
			try {
				return Context.getType(candidate);
			} catch (_:Dynamic) {}
		}
		Context.error("@:railsMailerParams could not resolve params typedef `" + typeNameForError(expr) + "`.", expr.pos);
		return Context.getType("Dynamic");
	}

	static function paramsComplexType(expr:Expr, owner:ClassType):ComplexType {
		return switch (typePathParts(expr)) {
			case null:
				Context.error("@:railsMailerParams expects a type path, not an arbitrary expression.", expr.pos);
				macro :Dynamic;
			case parts:
				var name = parts.pop();
				if (name == null) {
					Context.error("@:railsMailerParams expects a non-empty type path.", expr.pos);
					macro :Dynamic;
				} else if (parts.length == 0) {
					TPath({
						pack: [],
						name: name,
						params: [],
						sub: null
					});
				} else {
					TPath({
						pack: parts,
						name: name,
						params: [],
						sub: null
					});
				}
		}
	}

	static function typeNameCandidates(expr:Expr, owner:ClassType):Array<String> {
		return switch (typePathParts(expr)) {
			case null: [];
			case parts:
				var explicit = parts.join(".");
				if (parts.length == 1 && owner.pack.length > 0) {
					[owner.pack.concat(parts).join("."), explicit];
				} else {
					[explicit];
				}
		}
	}

	static function typePathParts(expr:Expr):Null<Array<String>> {
		return switch (expr.expr) {
			case EConst(CIdent(name)):
				[name];
			case EField(target, name):
				var targetParts = typePathParts(target);
				targetParts == null ? null : targetParts.concat([name]);
			case EParenthesis(inner) | ECheckType(inner, _):
				typePathParts(inner);
			case _:
				null;
		}
	}

	static function typeNameForError(expr:Expr):String {
		return switch (typePathParts(expr)) {
			case null: "<invalid>";
			case parts: parts.join(".");
		}
	}

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
						ownedTemplatePath(path);
					case "existing":
						var value = extractString(path, "Template.existing expects a string literal path.");
						validateTemplatePath(value, path.pos, "Template.existing");
						validateExternalTemplateExists(value, path.pos);
						normalizeRenderPath(value);
					case _:
						throw "MailerMacro expects Template.of(...), Template.named(...), Template.existing(...), or Template.external(...) as the template argument.";
				}
			case _:
				throw "MailerMacro expects Template.of(...), Template.named(...), Template.existing(...), or Template.external(...) as the template argument.";
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

	static function ownedTemplatePath(view:Expr):String {
		var classType = switch (Context.typeExpr(view).expr) {
			case TTypeExpr(TClassDecl(classRef)):
				classRef.get();
			case _:
				Context.error("Template.of expects a RailsHx view class reference.", view.pos);
				return "";
		}
		var path = metaStringParam(classType.meta, ":railsTemplate", 0);
		if (path == null) {
			Context.error("Template.of expects a class annotated with @:railsTemplate(\"path\").", view.pos);
			return "";
		}
		validateTemplatePath(path, view.pos, "@:railsTemplate");
		return normalizeRenderPath(path);
	}

	static function validateLocalsObject(locals:Expr):Void {
		if (localsFields(locals).length == 0) {
			throw "MailerMacro locals must include at least one typed field.";
		}
	}

	static function validateLocalsType(template:Expr, locals:Expr, context:String):Void {
		var expected = switch (Context.typeof(template)) {
			case TInst(classRef, [localsType]) if (classRef.get().pack.join(".") == "rails.action_view"
				&& classRef.get().name == "Template"):
				localsType;
			case _:
				Context.error(context + " template argument must be rails.action_view.Template<TLocals>.", template.pos);
				return;
		}
		var actual = Context.typeof(locals);
		if (!Context.unify(actual, expected)) {
			Context.error(context + " locals do not match the Template<TLocals> contract.", locals.pos);
		}
	}

	static function railsLocalsObject(locals:Expr):Expr {
		return switch (locals.expr) {
			case EObjectDecl(fields):
				{
					expr: EObjectDecl([
						for (field in fields)
							{
								field: RubyNaming.toLocalName(field.field),
								expr: field.expr,
								quotes: field.quotes
							}
					]),
					pos: locals.pos
				};
			case _:
				{
					expr: EObjectDecl([
						for (field in localsFields(locals))
							{
								field: RubyNaming.toLocalName(field),
								expr: {expr: EField(locals, field), pos: locals.pos},
								quotes: null
							}
					]),
					pos: locals.pos
				};
		}
	}

	static function localsFields(locals:Expr):Array<String> {
		return switch (locals.expr) {
			case EObjectDecl(fields):
				[for (field in fields) field.field];
			case _:
				switch (TypeTools.follow(Context.typeof(locals))) {
					case TAnonymous(anonRef):
						[for (field in anonRef.get().fields) field.name];
					case _:
						Context.error("MailerMacro locals must be an object literal or a typed anonymous-object/typedef value.", locals.pos);
						[];
				}
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
