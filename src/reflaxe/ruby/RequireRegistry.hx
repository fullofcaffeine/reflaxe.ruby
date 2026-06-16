package reflaxe.ruby;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Expr.MetadataEntry;
import haxe.macro.Type;
import haxe.macro.Type.MetaAccess;
import haxe.macro.Type.ModuleType;
import reflaxe.compiler.TypeUsageTracker.TypeOrModuleType;
import reflaxe.compiler.TypeUsageTracker.TypeUsageMap;

class RequireRegistry {
	final requires:Array<String> = [];
	final requireRelatives:Array<String> = [];

	public function new() {}

	public function addRequire(value:String):Void {
		addUnique(requires, value);
	}

	public function addRequireRelative(value:String):Void {
		addUnique(requireRelatives, value);
	}

	public function addAll(other:RequireRegistry):Void {
		for (value in other.requireValues()) {
			addRequire(value);
		}
		for (value in other.requireRelativeValues()) {
			addRequireRelative(value);
		}
	}

	public function collectMeta(meta:Null<MetaAccess>):Void {
		for (entry in extractMeta(meta, ":rubyRequire")) {
			addRequire(extractStringParam(entry, "@:rubyRequire"));
		}
		for (entry in extractMeta(meta, ":rubyRequireRelative")) {
			addRequireRelative(extractStringParam(entry, "@:rubyRequireRelative"));
		}
	}

	public function collectTypeUsage(usage:Null<TypeUsageMap>):Void {
		if (usage == null) {
			return;
		}
		for (level in usage.keys()) {
			var items = usage.get(level);
			if (items == null) {
				continue;
			}
			for (item in items) {
				switch (item) {
					case EModuleType(moduleType):
						collectModuleType(moduleType);
					case EType(type):
						collectType(type);
				}
			}
		}
	}

	public function requireValues():Array<String> {
		var out = requires.copy();
		out.sort(Reflect.compare);
		return out;
	}

	public function requireRelativeValues():Array<String> {
		var out = requireRelatives.copy();
		out.sort(Reflect.compare);
		return out;
	}

	function collectModuleType(moduleType:Null<ModuleType>):Void {
		if (moduleType == null) {
			return;
		}
		switch (moduleType) {
			case TClassDecl(classRef):
				collectMeta(classRef.get().meta);
			case TEnumDecl(enumRef):
				collectMeta(enumRef.get().meta);
			case TTypeDecl(typeRef):
				collectMeta(typeRef.get().meta);
			case TAbstract(abstractRef):
				collectMeta(abstractRef.get().meta);
		}
	}

	function collectType(type:Null<Type>):Void {
		if (type == null) {
			return;
		}
		switch (type) {
			case TInst(classRef, params):
				collectMeta(classRef.get().meta);
				for (param in params)
					collectType(param);
			case TEnum(enumRef, params):
				collectMeta(enumRef.get().meta);
				for (param in params)
					collectType(param);
			case TType(typeRef, params):
				collectMeta(typeRef.get().meta);
				for (param in params)
					collectType(param);
			case TAbstract(abstractRef, params):
				collectMeta(abstractRef.get().meta);
				for (param in params)
					collectType(param);
			case TFun(args, ret):
				for (arg in args)
					collectType(arg.t);
				collectType(ret);
			case TAnonymous(anonRef):
				for (field in anonRef.get().fields)
					collectType(field.type);
			case TDynamic(inner):
				collectType(inner);
			case TLazy(lazy):
				collectType(lazy());
			case TMono(_):
		}
	}

	static function extractMeta(meta:Null<MetaAccess>, name:String):Array<MetadataEntry> {
		if (meta == null || meta.extract == null) {
			return [];
		}
		return meta.extract(name);
	}

	static function extractStringParam(entry:MetadataEntry, label:String):String {
		if (entry.params == null || entry.params.length != 1) {
			Context.error(label + " expects exactly one string literal argument.", entry.pos);
			return "";
		}
		return switch (entry.params[0].expr) {
			case EConst(CString(value, _)) if (value.length > 0):
				value;
			case _:
				Context.error(label + " expects a non-empty string literal argument.", entry.params[0].pos);
				"";
		}
	}

	static function addUnique(target:Array<String>, value:String):Void {
		if (target.indexOf(value) == -1) {
			target.push(value);
		}
	}
}
#end
