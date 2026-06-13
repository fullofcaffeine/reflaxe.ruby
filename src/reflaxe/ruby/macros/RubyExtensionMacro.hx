package reflaxe.ruby.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Expr;
import haxe.macro.Expr.Field;
import haxe.macro.Expr.Metadata;
import haxe.macro.Expr.MetadataEntry;
import haxe.macro.Expr.Position;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.MetaAccess;

class RubyExtensionMacro {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var localClass = Context.getLocalClass();
		if (localClass == null) {
			return fields;
		}
		var cls = localClass.get();
		var pos = Context.currentPos();
		applyContracts(fields, cls, extractMeta(cls.meta, ":rubyInclude"), false, cls.isExtern, pos);
		applyContracts(fields, cls, extractMeta(cls.meta, ":rubyPrepend"), false, cls.isExtern, pos);
		applyContracts(fields, cls, extractMeta(cls.meta, ":rubyExtend"), true, cls.isExtern, pos);
		return fields;
	}

	static function applyContracts(fields:Array<Field>, owner:ClassType, entries:Array<MetadataEntry>, staticOnly:Bool, targetIsExtern:Bool, pos:Position):Void {
		for (entry in entries) {
			if (entry.params == null || entry.params.length == 0) {
				Context.error(entry.name + " expects an extension contract type.", entry.pos);
				continue;
			}
			var contract = contractType(entry.params[0], owner, entry.name);
			if (contract == null) {
				continue;
			}
			var sourceFields = staticOnly && !isRubyModuleContract(contract) ? contract.statics.get() : contract.fields.get();
			for (source in sourceFields) {
				if (!source.isPublic || source.name == "new") {
					continue;
				}
				injectField(fields, source, staticOnly, targetIsExtern, entry.name, pos);
			}
		}
	}

	static function contractType(expr:Expr, owner:ClassType, metaName:String):Null<ClassType> {
		var path = typePathExpr(expr);
		if (path == null) {
			Context.error(metaName + " expects a type path such as SluggableMethods.", expr.pos);
			return null;
		}
		var resolved = tryGetType(path);
		if (resolved == null && owner.module != null && owner.module != "" && path.indexOf(".") == -1) {
			resolved = tryGetType(owner.module + "." + path);
		}
		if (resolved == null) {
			Context.error(metaName + " contract " + path + " could not be resolved.", expr.pos);
			return null;
		}
		return switch (resolved) {
			case TInst(ref, _): ref.get();
			case _:
				Context.error(metaName + " contract " + path + " must resolve to a class or interface.", expr.pos);
				null;
		}
	}

	static function tryGetType(path:String):Null<haxe.macro.Type> {
		try {
			return Context.getType(path);
		} catch (_:Dynamic) {
			return null;
		}
	}

	static function injectField(fields:Array<Field>, source:ClassField, isStatic:Bool, targetIsExtern:Bool, metaName:String, pos:Position):Void {
		var existing = findField(fields, source.name);
		if (existing != null) {
			if (!hasMeta(existing.meta, ":rubyExtensionOverride") && !hasMeta(existing.meta, ":rubyInjectedExtension")) {
				Context.error(metaName + " cannot inject " + source.name + " because the target already defines it. Add @:rubyExtensionOverride to the target field if this is intentional.", existing.pos);
			}
			return;
		}
		switch (resolvedFieldType(source.type)) {
			case TFun(args, ret):
				fields.push({
					name: source.name,
					access: isStatic ? [APublic, AStatic] : [APublic],
					kind: FFun({
						args: [for (arg in args) {name: arg.name, opt: arg.opt, type: Context.toComplexType(arg.t)}],
						ret: Context.toComplexType(ret),
						expr: targetIsExtern ? null : macro return cast null
					}),
					meta: copiedMetadata(source.meta, pos),
					pos: pos
				});
			case _:
				fields.push({
					name: source.name,
					access: isStatic ? [APublic, AStatic] : [APublic],
					kind: FVar(Context.toComplexType(source.type), null),
					meta: copiedMetadata(source.meta, pos),
					pos: pos
				});
		}
	}

	static function copiedMetadata(meta:MetaAccess, pos:Position):Metadata {
		var out:Metadata = [
			{name: ":rubyExternStub", params: [], pos: pos},
			{name: ":rubyInjectedExtension", params: [], pos: pos}
		];
		for (name in [":native", ":rubyKwargs", ":rubyBlockArg"]) {
			for (entry in meta.extract(name)) {
				out.push({name: entry.name, params: entry.params, pos: entry.pos});
			}
		}
		return out;
	}

	static function resolvedFieldType(type:haxe.macro.Type):haxe.macro.Type {
		return try {
			Context.follow(type);
		} catch (_:Dynamic) {
			type;
		}
	}

	static function typePathExpr(expr:Expr):Null<String> {
		return switch (expr.expr) {
			case EConst(CIdent(name)): name;
			case EField(target, field):
				var parent = typePathExpr(target);
				parent == null ? null : parent + "." + field;
			case _:
				null;
		}
	}

	static function findField(fields:Array<Field>, name:String):Null<Field> {
		for (field in fields) {
			if (field.name == name) {
				return field;
			}
		}
		return null;
	}

	static function hasMeta(meta:Null<Metadata>, name:String):Bool {
		if (meta == null) {
			return false;
		}
		for (entry in meta) {
			if (entry.name == name) {
				return true;
			}
		}
		return false;
	}

	static function isRubyModuleContract(contract:ClassType):Bool {
		return hasTypeMeta(contract.meta, ":rubyModule") || hasTypeMeta(contract.meta, ":rubyConcern");
	}

	static function hasTypeMeta(meta:Null<MetaAccess>, name:String):Bool {
		return meta != null && meta.has != null && meta.has(name);
	}

	static function extractMeta(meta:Null<MetaAccess>, name:String):Array<MetadataEntry> {
		if (meta == null || meta.extract == null) {
			return [];
		}
		return meta.extract(name);
	}
}
#else
class RubyExtensionMacro {}
#end
