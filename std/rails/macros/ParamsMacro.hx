package rails.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.FieldAccess;
import haxe.macro.Type.MetaAccess;
import haxe.macro.Type.TypedExpr;
#else
import haxe.macro.Expr;
#end
import reflaxe.ruby.naming.RubyNaming;

#if macro
private typedef FieldInfo = {
	name:String,
	model:Null<String>
}
#end

class ParamsMacro {
	public static macro function requirePermit(params:Expr, root:Expr, fields:Expr):Expr {
		var rootModel = typedRailsModelKey(root);
		var fieldInfos = switch (fields.expr) {
			case EArrayDecl(values):
				[for (value in values) fieldInfo(value)];
			case _:
				throw "ParamsMacro.requirePermit expects an array literal of field names.";
				[];
		}
		validateFieldModels(rootModel, fieldInfos, fields.pos);
		var symbols = [for (info in fieldInfos) macro ruby.Symbol.of($v{RubyNaming.toMethodName(info.name)})];
		return macro $params.requireParam($root).permit([$a{symbols}]);
	}

	#if macro
	static function fieldInfo(expr:Expr):FieldInfo {
		return switch (expr.expr) {
			case EConst(CString(value, _)):
				{name: value, model: null};
			case _:
				var sourceInfo = sourceRailsFieldInfo(expr);
				var info = sourceInfo == null ? typedRailsFieldInfo(expr) : extractRailsFieldInfo(Context.typeExpr(expr));
				if (info == null) {
					throw "ParamsMacro.requirePermit fields must be string literals or generated RailsHx model field refs such as Todo.titleField.";
				}
				if (sourceInfo != null && info.model == null) {
					info.model = sourceInfo.model;
				}
				info;
		}
	}

	static function typedRailsFieldInfo(expr:Expr):Null<FieldInfo> {
		return try {
			extractRailsFieldInfo(Context.typeExpr(expr));
		} catch (_:Dynamic) {
			null;
		}
	}

	static function typedRailsModelKey(expr:Expr):Null<String> {
		var sourceModel = sourceRailsModelKey(expr);
		if (sourceModel != null) {
			return sourceModel;
		}
		return try {
			extractRailsModelKey(Context.typeExpr(expr));
		} catch (_:Dynamic) {
			null;
		}
	}

	static function sourceRailsFieldInfo(expr:Expr):Null<FieldInfo> {
		return switch (expr.expr) {
			case EField(owner, field) if (StringTools.endsWith(field, "Field")):
				{name: field.substr(0, field.length - "Field".length), model: sourceExprName(owner)};
			case EParenthesis(inner) | ECheckType(inner, _):
				sourceRailsFieldInfo(inner);
			case _:
				null;
		}
	}

	static function sourceRailsModelKey(expr:Expr):Null<String> {
		return switch (expr.expr) {
			case EField(owner, "railsParamKey"):
				sourceExprName(owner);
			case EParenthesis(inner) | ECheckType(inner, _):
				sourceRailsModelKey(inner);
			case _:
				null;
		}
	}

	static function sourceExprName(expr:Expr):Null<String> {
		return switch (expr.expr) {
			case EConst(CIdent(name)):
				name;
			case EField(owner, field):
				var prefix = sourceExprName(owner);
				prefix == null ? field : prefix + "." + field;
			case _:
				null;
		}
	}

	static function extractRailsModelKey(expr:TypedExpr):Null<String> {
		return switch (expr.expr) {
			case TMeta(_, inner) | TParenthesis(inner) | TCast(inner, _):
				extractRailsModelKey(inner);
			case TField(_, access) if (fieldAccessRawName(access) == "railsParamKey"):
				var model = genericModelName(expr.t, "ModelKey");
				model == null ? fieldAccessOwnerModelName(access) : model;
			case _:
				genericModelName(expr.t, "ModelKey");
		}
	}

	static function extractRailsFieldInfo(expr:TypedExpr):Null<FieldInfo> {
		return switch (expr.expr) {
			case TMeta(_, inner) | TParenthesis(inner) | TCast(inner, _):
				extractRailsFieldInfo(inner);
			case TField(_, access):
				var model = genericModelName(expr.t, "Field");
				var name = fieldAccessRailsFieldName(access);
				if (name == null) {
					name = fieldAccessGeneratedFieldName(access);
				}
				if (name != null && model == null) {
					model = fieldAccessOwnerModelName(access);
				}
				name == null ? null : {name: name, model: model};
			case TConst(TString(value)):
				{name: value, model: null};
			case _:
				null;
		}
	}

	static function validateFieldModels(rootModel:Null<String>, fields:Array<FieldInfo>, pos:Position):Void {
		var expected = rootModel;
		for (field in fields) {
			if (field.model == null) {
				continue;
			}
			if (expected == null) {
				expected = field.model;
				continue;
			}
			if (field.model != expected) {
				Context.error("ParamsMacro.requirePermit field refs must belong to the same model as the typed params root.", pos);
			}
		}
	}

	static function fieldAccessRailsFieldName(access:FieldAccess):Null<String> {
		var meta = switch (access) {
			case FInstance(_, _, field) | FStatic(_, field): field.get().meta;
			case FAnon(fieldRef) | FClosure(_, fieldRef): fieldRef.get().meta;
			case FEnum(_, field): field.meta;
			case FDynamic(_): null;
		}
		return metaStringParam(meta, ":railsField", 0);
	}

	static function fieldAccessGeneratedFieldName(access:FieldAccess):Null<String> {
		var raw = fieldAccessRawName(access);
		return StringTools.endsWith(raw, "Field") ? raw.substr(0, raw.length - "Field".length) : null;
	}

	static function fieldAccessRawName(access:FieldAccess):String {
		return switch (access) {
			case FInstance(_, _, field) | FStatic(_, field): field.get().name;
			case FAnon(fieldRef) | FClosure(_, fieldRef): fieldRef.get().name;
			case FEnum(_, field): field.name;
			case FDynamic(name): name;
		}
	}

	static function fieldAccessOwnerModelName(access:FieldAccess):Null<String> {
		return switch (access) {
			case FStatic(classRef, _):
				var cls = classRef.get();
				(cls.pack.length == 0 ? "" : cls.pack.join(".") + ".") + cls.name;
			case _:
				null;
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

	static function genericModelName(type:haxe.macro.Type, expectedName:String):Null<String> {
		return switch (type) {
			case TAbstract(absRef, params):
				var abs = absRef.get();
				if (abs.pack.join(".") == "rails.active_record" && abs.name == expectedName && params.length > 0) {
					typeName(params[0]);
				} else {
					null;
				}
			case TLazy(lazy):
				genericModelName(lazy(), expectedName);
			case TType(_, params) if (params.length > 0):
				genericModelName(params[0], expectedName);
			case _:
				null;
		}
	}

	static function typeName(type:haxe.macro.Type):String {
		return switch (type) {
			case TInst(classRef, _):
				var cls = classRef.get();
				(cls.pack.length == 0 ? "" : cls.pack.join(".") + ".") + cls.name;
			case TType(typeRef, params):
				typeName(Context.follow(type));
			case TAbstract(absRef, _):
				var abs = absRef.get();
				(abs.pack.length == 0 ? "" : abs.pack.join(".") + ".") + abs.name;
			case TLazy(lazy):
				typeName(lazy());
			case _:
				Std.string(type);
		}
	}
	#end
}
