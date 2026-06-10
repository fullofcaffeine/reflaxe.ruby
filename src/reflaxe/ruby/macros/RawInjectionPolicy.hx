package reflaxe.ruby.macros;

#if macro
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import sys.FileSystem;
import sys.io.File;

class RawInjectionPolicy {
	public static inline final INJECTION_NAME = "__ruby__";
	public static inline final ALLOW_RAW_META = ":rubyAllowRaw";

	public static function enforce(types:Array<ModuleType>, sourceAllowed:ClassType->Bool, message:String):Void {
		var allowed = allowedRawInjectionModules(types);
		for (moduleType in types) {
			switch (moduleType) {
				case TClassDecl(classRef):
					var classType = classRef.get();
					if (!sourceAllowed(classType)) {
						continue;
					}
					scanClass(classType, allowed.exists(moduleNameForClass(classType)), message);
				case TAbstract(abstractRef):
					var abstractType = abstractRef.get();
					if (abstractType.impl == null) {
						continue;
					}
					var impl = abstractType.impl.get();
					if (impl == null) {
						continue;
					}
					var classLike = impl;
					if (!sourceAllowed(classLike)) {
						continue;
					}
					scanFields(impl.fields.get().concat(impl.statics.get()), allowed.exists(moduleNameForAbstract(abstractType)), message);
				case _:
			}
		}
	}

	public static function scanClass(classType:ClassType, allowScopedRawAuthority:Bool, message:String):Void {
		scanFields(classType.fields.get().concat(classType.statics.get()), allowScopedRawAuthority, message);
	}

	public static function scanFields(fields:Array<ClassField>, allowScopedRawAuthority:Bool, message:String):Void {
		for (field in fields) {
			var expr = field.expr();
			if (expr == null) {
				continue;
			}
			scanExpr(expr, allowScopedRawAuthority, message);
		}
	}

	public static function scanExpr(expr:TypedExpr, allowScopedRawAuthority:Bool, message:String):Void {
		if (isRubyInjectionCall(expr) && !allowScopedRawAuthority) {
			Context.error(message, expr.pos);
		}
		TypedExprTools.iter(expr, e -> scanExpr(e, allowScopedRawAuthority, message));
	}

	public static function isRubyInjectionCall(expr:TypedExpr):Bool {
		return switch (expr.expr) {
			case TCall(callTarget, _):
				switch (callTarget.expr) {
					case TIdent(name):
						name == INJECTION_NAME;
					case TLocal(variable):
						variable.name == INJECTION_NAME;
					case TField(_, fieldAccess):
						switch (fieldAccess) {
							case FInstance(_, _, classField) | FStatic(_, classField) | FAnon(classField) | FClosure(_, classField):
								classField.get().name == INJECTION_NAME;
							case FEnum(_, enumField):
								enumField.name == INJECTION_NAME;
							case FDynamic(name):
								name == INJECTION_NAME;
						}
					case _:
						false;
				}
			case _:
				false;
		}
	}

	public static function preflightFindings(predicate:String->Bool):Array<String> {
		var files = new Array<String>();
		for (classPath in Context.getClassPath()) {
			var full = absolutePath(classPath);
			if (!predicate(full)) {
				continue;
			}
			collectHxFiles(full, files);
		}

		var findings = new Array<String>();
		for (path in files) {
			var content = File.getContent(path);
			if (StringTools.contains(content, INJECTION_NAME + "(") && !sourceTextHasRawAuthorityMarker(content)) {
				findings.push(path);
			}
		}
		return findings;
	}

	public static function isExampleOrTestSource(path:String):Bool {
		var normalized = normalizePath(path);
		return normalized.indexOf("/examples/") != -1 || normalized.indexOf("/test/") != -1;
	}

	public static function isProjectSource(path:String, projectRoot:String):Bool {
		var normalized = normalizePath(path);
		var root = ensureTrailingSlash(projectRoot);
		return StringTools.startsWith(normalized, root) && normalized.indexOf("/src/reflaxe/") == -1 && normalized.indexOf("/std/") == -1;
	}

	public static function isClassUnderExampleOrTest(classType:ClassType):Bool {
		return isExampleOrTestSource(positionFile(classType.pos));
	}

	public static function isClassUnderProject(classType:ClassType, projectRoot:String):Bool {
		return isProjectSource(positionFile(classType.pos), projectRoot);
	}

	public static function absolutePath(path:String):String {
		if (Path.isAbsolute(path)) {
			return normalizePath(path);
		}
		return normalizePath(Path.join([Sys.getCwd(), path]));
	}

	public static function normalizePath(path:String):String {
		return Path.normalize(path).split("\\").join("/");
	}

	public static function ensureTrailingSlash(path:String):String {
		var normalized = normalizePath(path);
		return StringTools.endsWith(normalized, "/") ? normalized : normalized + "/";
	}

	static function collectHxFiles(path:String, out:Array<String>):Void {
		if (!FileSystem.exists(path)) {
			return;
		}
		if (FileSystem.isDirectory(path)) {
			for (entry in FileSystem.readDirectory(path)) {
				collectHxFiles(Path.join([path, entry]), out);
			}
			return;
		}
		if (StringTools.endsWith(path, ".hx")) {
			out.push(normalizePath(path));
		}
	}

	static function sourceTextHasRawAuthorityMarker(content:String):Bool {
		return StringTools.contains(content, "@:rubyAllowRaw");
	}

	static function allowedRawInjectionModules(types:Array<ModuleType>):Map<String, Bool> {
		var out:Map<String, Bool> = [];
		for (moduleType in types) {
			switch (moduleType) {
				case TClassDecl(classRef):
					var classType = classRef.get();
					if (hasMeta(classType.meta, ALLOW_RAW_META)) {
						out.set(moduleNameForClass(classType), true);
					}
				case TAbstract(abstractRef):
					var abstractType = abstractRef.get();
					if (hasMeta(abstractType.meta, ALLOW_RAW_META)) {
						out.set(moduleNameForAbstract(abstractType), true);
					}
				case _:
			}
		}
		return out;
	}

	static function hasMeta(meta:Null<haxe.macro.Type.MetaAccess>, name:String):Bool {
		return meta != null && meta.has != null && meta.has(name);
	}

	static function moduleNameForClass(classType:ClassType):String {
		if (classType.module != null && classType.module.length > 0) {
			return classType.module;
		}
		return pathFromPack(classType.pack, classType.name);
	}

	static function moduleNameForAbstract(abstractType:AbstractType):String {
		if (abstractType.module != null && abstractType.module.length > 0) {
			return abstractType.module;
		}
		return pathFromPack(abstractType.pack, abstractType.name);
	}

	static function pathFromPack(pack:Array<String>, name:String):String {
		return pack == null || pack.length == 0 ? name : pack.join(".") + "." + name;
	}

	static function positionFile(pos:haxe.macro.Expr.Position):String {
		var file = Context.getPosInfos(pos).file;
		if (file == null || file == "") {
			return "";
		}
		if (Path.isAbsolute(file)) {
			return normalizePath(file);
		}
		return normalizePath(Path.join([Sys.getCwd(), file]));
	}
}
#else
class RawInjectionPolicy {}
#end
