package rails.active_record;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Type.FieldAccess;
import haxe.macro.Type.MetaAccess;
import haxe.macro.Type.TypedExpr;

private typedef GroupFieldInfo = {
	name:String,
	model:Null<String>,
	valueType:Type,
	pos:Position
}
#end

class Group {
	public static macro function count(source:Expr, field:Expr):Expr {
		#if macro
		var sourceModel = sourceModelName(source);
		if (sourceModel == null) {
			Context.error("Group.count source must be a @:railsModel class or Relation<TModel, TCriteria>.", source.pos);
		}
		var info = fieldInfo(field);
		if (info == null || info.model == null) {
			Context.error("Group.count field must be a generated RailsHx model field ref such as Todo.f.status.", field.pos);
		}
		if (!sameModelName(info.model, sourceModel)) {
			Context.error("Group.count field refs must belong to the same model as the source.", field.pos);
		}
		var keyKind = groupKeyKind(info.valueType, field.pos);
		var ret = groupReturnType(keyKind);
		var call = macro rails.active_record.GroupRuntime.count($source, $v{info.name}, $v{keyKind});
		return {
			expr: ECheckType({expr: ECast(call, null), pos: field.pos}, ret),
			pos: field.pos
		};
		#else
		return macro null;
		#end
	}

	public static macro function countHaving(source:Expr, field:Expr, predicate:Expr):Expr {
		#if macro
		var sourceModel = sourceModelName(source);
		if (sourceModel == null) {
			Context.error("Group.countHaving source must be a @:railsModel class or Relation<TModel, TCriteria>.", source.pos);
		}
		var info = fieldInfo(field);
		if (info == null || info.model == null) {
			Context.error("Group.countHaving field must be a generated RailsHx model field ref such as Todo.f.status.", field.pos);
		}
		if (!sameModelName(info.model, sourceModel)) {
			Context.error("Group.countHaving field refs must belong to the same model as the source.", field.pos);
		}
		var predicateModel = predicateModelName(predicate);
		if (predicateModel == null) {
			Context.error("Group.countHaving predicate must be a typed Predicate<TModel>, usually produced by Aggregate.count(...).gt(...).", predicate.pos);
		}
		if (!sameModelName(predicateModel, sourceModel)) {
			Context.error("Group.countHaving predicate refs must belong to the same model as the source.", predicate.pos);
		}
		var keyKind = groupKeyKind(info.valueType, field.pos);
		var ret = groupReturnType(keyKind);
		var call = macro rails.active_record.GroupRuntime.countHaving($source, $v{info.name}, $v{keyKind}, $predicate);
		return {
			expr: ECheckType({expr: ECast(call, null), pos: field.pos}, ret),
			pos: field.pos
		};
		#else
		return macro null;
		#end
	}

	#if macro
	static function groupKeyKind(type:Type, pos:Position):String {
		return switch (typeName(type)) {
			case "String": "string";
			case "Int": "int";
			case other:
				Context.error("Group.count only supports String and Int fields in v1; unsupported field type: " + other + ".", pos);
				"unsupported";
		}
	}

	static function groupReturnType(keyKind:String):ComplexType {
		var mapName = keyKind == "int" ? "IntMap" : "StringMap";
		return TPath({
			pack: ["haxe", "ds"],
			name: mapName,
			params: [TPType(macro : Int)]
		});
	}

	static function fieldInfo(expr:Expr):Null<GroupFieldInfo> {
		var typed = try {
			Context.typeExpr(expr);
		} catch (_:Dynamic) {
			return null;
		}
		return extractRailsFieldInfo(typed);
	}

	static function extractRailsFieldInfo(expr:TypedExpr):Null<GroupFieldInfo> {
		return switch (expr.expr) {
			case TMeta(_, inner) | TParenthesis(inner) | TCast(inner, _):
				extractRailsFieldInfo(inner);
			case TField(_, access):
				var params = fieldTypeParams(expr.t);
				if (params == null) {
					return null;
				}
				var name = fieldAccessRailsFieldName(access);
				if (name == null) {
					name = fieldAccessGeneratedFieldName(access);
				}
				name == null ? null : {
					name: name,
					model: typeName(params.model),
					valueType: params.value,
					pos: expr.pos
				};
			case _:
				null;
		}
	}

	static function sourceModelName(expr:Expr):Null<String> {
		var typed = try {
			Context.typeExpr(expr);
		} catch (_:Dynamic) {
			return null;
		}
		return switch (typed.expr) {
			case TTypeExpr(TClassDecl(classRef)):
				var cls = classRef.get();
				hasRailsModelMeta(cls.meta) ? (cls.pack.length == 0 ? "" : cls.pack.join(".") + ".") + cls.name : null;
			case _:
				relationModelName(typed.t);
		}
	}

	static function hasRailsModelMeta(meta:MetaAccess):Bool {
		return meta.extract(":railsModel").length > 0;
	}

	static function relationModelName(type:Type):Null<String> {
		return switch (type) {
			case TInst(classRef, params):
				var cls = classRef.get();
				if (cls.pack.join(".") == "rails.active_record" && cls.name == "Relation" && params.length > 0) {
					typeName(params[0]);
				} else {
					null;
				}
			case TType(_, _) | TAbstract(_, _):
				relationModelName(Context.follow(type));
			case TLazy(lazy):
				relationModelName(lazy());
			case _:
				null;
		}
	}

	static function predicateModelName(expr:Expr):Null<String> {
		var type = try {
			Context.typeof(expr);
		} catch (_:Dynamic) {
			return null;
		}
		return switch (type) {
			case TAbstract(absRef, params):
				var abs = absRef.get();
				if (abs.pack.join(".") == "rails.active_record" && abs.name == "Predicate" && params.length == 1) {
					typeName(params[0]);
				} else {
					predicateModelNameFromType(Context.follow(type));
				}
			case _:
				predicateModelNameFromType(type);
		}
	}

	static function predicateModelNameFromType(type:Type):Null<String> {
		return switch (type) {
			case TAbstract(absRef, params):
				var abs = absRef.get();
				if (abs.pack.join(".") == "rails.active_record" && abs.name == "Predicate" && params.length == 1) {
					typeName(params[0]);
				} else {
					predicateModelNameFromType(Context.follow(type));
				}
			case TType(_, _) | TLazy(_):
				predicateModelNameFromType(Context.follow(type));
			case _:
				null;
		}
	}

	static function fieldTypeParams(type:Type):Null<{model:Type, value:Type}> {
		return switch (type) {
			case TAbstract(absRef, params):
				var abs = absRef.get();
				if (abs.pack.join(".") == "rails.active_record" && abs.name == "Field" && params.length == 2) {
					{model: params[0], value: params[1]};
				} else {
					fieldTypeParams(Context.follow(type));
				}
			case TType(_, _):
				fieldTypeParams(Context.follow(type));
			case TLazy(lazy):
				fieldTypeParams(lazy());
			case _:
				null;
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

	static function sameModelName(left:String, right:String):Bool {
		if (left == right) {
			return true;
		}
		if (left.indexOf(".") >= 0 && right.indexOf(".") >= 0) {
			return false;
		}
		return shortModelName(left) == shortModelName(right);
	}

	static function shortModelName(name:String):String {
		var parts = name.split(".");
		return parts[parts.length - 1];
	}

	static function typeName(type:Type):String {
		return switch (type) {
			case TInst(classRef, _):
				var cls = classRef.get();
				(cls.pack.length == 0 ? "" : cls.pack.join(".") + ".") + cls.name;
			case TAbstract(absRef, _) if (absRef.get().pack.length == 0):
				absRef.get().name;
			case TType(_, _) | TAbstract(_, _):
				typeName(Context.follow(type));
			case TLazy(lazy):
				typeName(lazy());
			case _:
				Std.string(type);
		}
	}
	#end
}
