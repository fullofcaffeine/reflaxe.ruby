package rails.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.FieldAccess;
import haxe.macro.Type.MetaAccess;
import haxe.macro.Type.TypedExpr;
import haxe.macro.TypeTools;
#else
import haxe.macro.Expr;
#end
import reflaxe.ruby.naming.RubyNaming;

#if macro
private typedef FieldInfo = {
	name:String,
	model:Null<String>
}

private typedef PermitSpec = {
	name:String,
	model:Null<String>,
	children:Null<Array<PermitSpec>>
}
#end

class ParamsMacro {
	public static macro function requirePermit(params:Expr, root:Expr, fields:Expr, ?nested:Expr):Expr {
		var rootModel = typedRailsModelKey(root);
		var permit = permitSpecs(fields);
		if (nested != null && !isNullExpr(nested)) {
			permit = permit.concat(nestedPermitRootSpecs(nested));
		}
		validateFieldModels(rootModel, topLevelFieldInfos(permit), fields.pos);
		var permitted = macro $params.requireParam($root).permit($e{permitArrayExpr(permit)});
		// The macro knows the ModelKey<T> owner. Feed that type back as an expected
		// `PermittedParams<T>` result so Haxe retains the Rails strong-params runtime
		// object without a Dynamic/cast boundary.
		return {
			expr: ECheckType(permitted, permittedParamsComplexType(railsModelComplexType(root))),
			pos: permitted.pos
		};
	}

	public static macro function mergeField(params:Expr, field:Expr, value:Expr):Expr {
		var info = fieldInfo(field);
		if (info.model == null) {
			Context.error("ParamsMacro.mergeField expects a generated RailsHx model field ref such as Todo.f.userId.", field.pos);
		}
		var paramsModel = typedPermittedParamsModel(params);
		if (paramsModel != null && info.model != null && !sameModelName(paramsModel, info.model)) {
			Context.error("ParamsMacro.mergeField field refs must belong to the same model as the permitted params value.", field.pos);
		}
		return macro rails.action_controller.ParamsRuntime.mergeField($params, $field, $value);
	}

	#if macro
	static function permitSpecs(expr:Expr):Array<PermitSpec> {
		return switch (expr.expr) {
			case EArrayDecl(values):
				var specs:Array<PermitSpec> = [];
				for (value in values) {
					specs = specs.concat(permitSpecValue(value));
				}
				specs;
			case _:
				throw "ParamsMacro.requirePermit expects an array literal of field names or nested permit specs.";
				[];
		}
	}

	static function isNullExpr(expr:Expr):Bool {
		return switch (expr.expr) {
			case EConst(CIdent("null")):
				true;
			case _:
				false;
		}
	}

	static function permitSpecValue(expr:Expr):Array<PermitSpec> {
		return switch (expr.expr) {
			case EObjectDecl(fields):
				[
					for (field in fields)
						{
							name: field.field,
							model: null,
							children: nestedPermitSpecs(field.expr)
						}
				];
			case _:
				var info = fieldInfo(expr);
				[{name: info.name, model: info.model, children: null}];
		}
	}

	static function nestedPermitSpecs(expr:Expr):Array<PermitSpec> {
		return switch (expr.expr) {
			case EArrayDecl(values):
				var specs:Array<PermitSpec> = [];
				for (value in values) {
					specs = specs.concat(permitSpecValue(value));
				}
				specs;
			case _:
				Context.error("ParamsMacro.requirePermit nested permit specs must use array literals.", expr.pos);
				[];
		}
	}

	static function nestedPermitRootSpecs(expr:Expr):Array<PermitSpec> {
		return switch (expr.expr) {
			case EObjectDecl(fields):
				[
					for (field in fields)
						{
							name: field.field,
							model: null,
							children: nestedPermitSpecs(field.expr)
						}
				];
			case _:
				Context.error("ParamsMacro.requirePermit nested root specs must use an object literal.", expr.pos);
				[];
		}
	}

	static function topLevelFieldInfos(specs:Array<PermitSpec>):Array<FieldInfo> {
		return [
			for (spec in specs)
				if (spec.children == null) {name: spec.name, model: spec.model}
		];
	}

	static function permitArrayExpr(specs:Array<PermitSpec>):Expr {
		return {
			expr: EArrayDecl([for (spec in specs) permitSpecExpr(spec)]),
			pos: Context.currentPos()
		};
	}

	static function permitSpecExpr(spec:PermitSpec):Expr {
		var name = RubyNaming.toMethodName(spec.name);
		if (spec.children == null) {
			return macro rails.action_controller.PermitSpec.field($v{name});
		}
		return macro rails.action_controller.PermitSpec.nested($v{name}, $e{permitArrayExpr(spec.children)});
	}

	static function fieldInfo(expr:Expr):FieldInfo {
		return switch (expr.expr) {
			case EConst(CString(value, _)):
				{name: value, model: null};
			case _:
				var sourceInfo = sourceRailsFieldInfo(expr);
				var info = sourceInfo == null ? typedRailsFieldInfo(expr) : extractRailsFieldInfo(Context.typeExpr(expr));
				if (info == null) {
					throw "ParamsMacro.requirePermit fields must be string literals or generated RailsHx model field refs such as Todo.f.title.";
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
		var typedModel = try {
			extractRailsModelKey(Context.typeExpr(expr));
		} catch (_:Dynamic) {
			null;
		}
		if (typedModel != null) {
			return typedModel;
		}
		return sourceRailsModelKey(expr);
	}

	static function typedRailsModelType(expr:Expr):Null<haxe.macro.Type> {
		return try {
			extractRailsModelType(Context.typeExpr(expr));
		} catch (_:Dynamic) {
			// Haxe's macro typer can throw non-Exception compiler values. This local
			// probe only enables a typed fallback; canonical ModelKey source syntax is
			// resolved without this seam and no Dynamic reaches the returned API.
			null;
		}
	}

	static function extractRailsModelType(expr:TypedExpr):Null<haxe.macro.Type> {
		return switch (expr.expr) {
			case TMeta(_, inner) | TParenthesis(inner) | TCast(inner, _):
				extractRailsModelType(inner);
			case _:
				genericModelType(expr.t, "ModelKey");
		}
	}

	static function railsModelComplexType(expr:Expr):Null<ComplexType> {
		var sourceName = sourceRailsModelKey(expr);
		if (sourceName != null) {
			var parts = sourceName.split(".");
			return TPath({pack: parts.slice(0, parts.length - 1), name: parts[parts.length - 1]});
		}
		var typed = typedRailsModelType(expr);
		return typed == null ? null : TypeTools.toComplexType(typed);
	}

	static function permittedParamsComplexType(modelType:Null<ComplexType>):ComplexType {
		var owner = modelType == null ? (macro :rails.action_controller.Params) : modelType;
		return TPath({
			pack: ["rails", "action_controller"],
			name: "PermittedParams",
			params: [TPType(owner)]
		});
	}

	static function typedPermittedParamsModel(expr:Expr):Null<String> {
		return try {
			permittedParamsModelName(Context.typeof(expr));
		} catch (_:Dynamic) {
			// Same macro-typer seam as typedRailsModelType; failure falls back to the
			// nominal Haxe signature, which still rejects incompatible model scopes.
			null;
		}
	}

	static function permittedParamsModelName(type:haxe.macro.Type):Null<String> {
		return switch (TypeTools.follow(type)) {
			case TInst(classRef, params):
				var cls = classRef.get();
				if (cls.pack.join(".") == "rails.action_controller" && cls.name == "PermittedParams" && params.length == 1) {
					typeName(params[0]);
				} else {
					null;
				}
			case _: null;
		}
	}

	static function sourceRailsFieldInfo(expr:Expr):Null<FieldInfo> {
		return switch (expr.expr) {
			case EField(owner, field) if (sourceFieldsOwnerModel(owner) != null):
				{name: field, model: sourceFieldsOwnerModel(owner)};
			case EField(owner, field) if (StringTools.endsWith(field, "Field")):
				{name: field.substr(0, field.length - "Field".length), model: sourceExprName(owner)};
			case EParenthesis(inner) | ECheckType(inner, _):
				sourceRailsFieldInfo(inner);
			case _:
				null;
		}
	}

	static function sourceFieldsOwnerModel(expr:Expr):Null<String> {
		return switch (expr.expr) {
			case EField(owner, "fields" | "f"):
				sourceExprName(owner);
			case EParenthesis(inner) | ECheckType(inner, _):
				sourceFieldsOwnerModel(inner);
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
			if (!sameModelName(field.model, expected)) {
				Context.error("ParamsMacro.requirePermit field refs must belong to the same model as the typed params root.", pos);
			}
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
		var modelType = genericModelType(type, expectedName);
		return modelType == null ? null : typeName(modelType);
	}

	static function genericModelType(type:haxe.macro.Type, expectedName:String):Null<haxe.macro.Type> {
		return switch (type) {
			case TAbstract(absRef, params):
				var abs = absRef.get();
				if (abs.pack.join(".") == "rails.active_record" && abs.name == expectedName && params.length > 0) {
					params[0];
				} else {
					null;
				}
			case TLazy(lazy):
				genericModelType(lazy(), expectedName);
			case TType(_, params) if (params.length > 0):
				genericModelType(params[0], expectedName);
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
