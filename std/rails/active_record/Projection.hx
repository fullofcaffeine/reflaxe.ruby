package rails.active_record;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Type.FieldAccess;
import haxe.macro.Type.MetaAccess;
import haxe.macro.Type.TypedExpr;
import haxe.macro.TypeTools;

private typedef ProjectionFieldInfo = {
	name:String,
	model:Null<String>,
	valueType:Type,
	pos:Position
}
#end

class Projection {
	public static macro function pluck(source:Expr, spec:Expr):Expr {
		#if macro
		var sourceModel = sourceModelName(source);
		if (sourceModel == null) {
			Context.error("Projection.pluck source must be a @:railsModel class or Relation<TModel, TCriteria>.", source.pos);
		}

		var fields = projectionFields(spec);
		var expectedModel = sourceModel;
		for (field in fields) {
			if (field.model == null) {
				Context.error("Projection.pluck specs must use generated RailsHx model field refs such as Todo.f.title.", field.pos);
			}
			if (!sameModelName(field.model, expectedModel)) {
				Context.error("Projection.pluck field refs must belong to the same model as the source.", field.pos);
			}
		}

		var rowFields:Array<Field> = [
			for (field in fields)
				{
					name: field.name,
					access: [],
					kind: FVar(TypeTools.toComplexType(field.valueType), null),
					pos: field.pos
				}
		];
		var rowType:ComplexType = TAnonymous(rowFields);
		var arrayType:ComplexType = TPath({
			pack: [],
			name: "Array",
			params: [TPType(rowType)]
		});
		var fieldNames = [for (field in fields) fieldSourceName(field.expr)];
		var keys = [for (field in fields) field.name];
		var call = macro rails.active_record.ProjectionRuntime.pluck($source, $e{stringArrayExpr(fieldNames)}, $e{stringArrayExpr(keys)});
		return {
			expr: ECheckType({expr: ECast(call, null), pos: spec.pos}, arrayType),
			pos: spec.pos
		};
		#else
		return macro null;
		#end
	}

	#if macro
	static function projectionFields(spec:Expr):Array<{name:String, expr:Expr, model:Null<String>, valueType:Type, pos:Position}> {
		return switch (spec.expr) {
			case EObjectDecl(values):
				if (values.length == 0) {
					Context.error("Projection.pluck spec must be a non-empty object literal.", spec.pos);
				}
				[
					for (value in values) {
						var info = fieldInfo(value.expr);
						if (info == null) {
							Context.error("Projection.pluck specs must use generated RailsHx model field refs such as Todo.f.title.", value.expr.pos);
						}
						{
							name: value.field,
							expr: value.expr,
							model: info.model,
							valueType: info.valueType,
							pos: value.expr.pos
						};
					}
				];
			case _:
				Context.error("Projection.pluck spec must be a non-empty object literal.", spec.pos);
				[];
		}
	}

	static function fieldInfo(expr:Expr):Null<ProjectionFieldInfo> {
		var typed = try {
			Context.typeExpr(expr);
		} catch (_:Dynamic) {
			return null;
		}
		return extractRailsFieldInfo(typed);
	}

	static function extractRailsFieldInfo(expr:TypedExpr):Null<ProjectionFieldInfo> {
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
				if (name == null) {
					return null;
				}
				{
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
			case TType(_, params) if (params.length > 0):
				relationModelName(Context.follow(type));
			case TAbstract(_, _):
				relationModelName(Context.follow(type));
			case TLazy(lazy):
				relationModelName(lazy());
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

	static function fieldSourceName(expr:Expr):String {
		var info = fieldInfo(expr);
		return info == null ? "" : info.name;
	}

	static function stringArrayExpr(values:Array<String>):Expr {
		return {
			expr: EArrayDecl([for (value in values) macro $v{value}]),
			pos: Context.currentPos()
		};
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
