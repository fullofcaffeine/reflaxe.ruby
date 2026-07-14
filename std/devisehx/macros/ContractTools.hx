package devisehx.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.MetadataEntry;
import haxe.macro.Type;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.TypedExpr;
import haxe.macro.TypeTools;

typedef DeviseRouteContract = {
	var schema:Int;
	var routeAuthorable:Bool;
	var resource:String;
	var mappingScope:String;
	var rubyClass:String;
	var haxeModel:String;
	var reason:String;
	var contractType:String;
	var contractField:String;
	var modelType:Type;
}

private typedef StaticFieldInfo = {
	final typeName:String;
	final fieldName:String;
	final field:ClassField;
}

typedef DeviseSignInOption = {
	final name:String;
	final value:Expr;
}

/** Companion-owned parsing and validation for generated Devise scope contracts. **/
class ContractTools {
	public static function routeContract(scope:Expr, context:String):DeviseRouteContract {
		var typed = Context.typeExpr(scope);
		var fieldInfo = staticFieldInfo(typed);
		if (fieldInfo == null) {
			Context.error(context
				+
				" expects a direct generated Devise scope field such as UserAuth.scope; runtime values, locals, function calls, and constructed scopes cannot be inspected safely.",
				scope.pos);
		}
		var meta = routeMeta(fieldInfo.field);
		if (meta == null) {
			Context.error(context + " expected a generated DeviseHx route contract on " + fieldInfo.typeName + "." + fieldInfo.fieldName
				+ ". Regenerate the contract.",
				scope.pos);
		}
		var contract = parseContractMeta(meta, scope.pos);
		if (contract.schema != 1) {
			Context.error("Unsupported DeviseHx route contract schema " + contract.schema + " on " + fieldInfo.typeName + "." + fieldInfo.fieldName
				+ ". Regenerate the contract with the current toolchain.",
				scope.pos);
		}
		contract.contractType = fieldInfo.typeName;
		contract.contractField = fieldInfo.fieldName;
		contract.modelType = scopeModelType(typed.t, scope.pos);
		validateName(contract.resource, "Devise route resource", scope.pos);
		validateName(contract.mappingScope, "Devise mapping scope", scope.pos);
		validateRubyClass(contract.rubyClass, scope.pos);
		validateHaxeModel(contract.modelType, contract.haxeModel, scope.pos);
		return contract;
	}

	public static function requireAuthorable(contract:DeviseRouteContract, pos:Position):Void {
		if (!contract.routeAuthorable) {
			Context.error("DeviseRoutes.deviseFor cannot author this adopted Devise route" + (contract.reason == "" ? "." : ": " + contract.reason), pos);
		}
	}

	public static function checked(expr:Expr, type:ComplexType):Expr {
		return {
			expr: ECheckType(expr, type),
			pos: expr.pos
		};
	}

	public static function modelComplexType(contract:DeviseRouteContract):ComplexType {
		var result = Context.toComplexType(contract.modelType);
		if (result == null) {
			Context.error("DeviseHx could not preserve the generated scope model type.", Context.currentPos());
		}
		return result;
	}

	public static function nullableModelComplexType(contract:DeviseRouteContract):ComplexType {
		return TPath({pack: [], name: "Null", params: [TPType(modelComplexType(contract))]});
	}

	public static function requireModel(expr:Expr, contract:DeviseRouteContract, context:String):Void {
		var actual = Context.typeof(expr);
		if (!Context.unify(actual, contract.modelType)) {
			Context.error(context + " resource type " + TypeTools.toString(actual) + " should be " + TypeTools.toString(contract.modelType) + ".", expr.pos);
		}
	}

	public static function sanitizerAction(expr:Expr):String {
		var typed = Context.typeExpr(expr);
		return switch (unwrapTyped(typed).expr) {
			case TField(_, access):
				var meta = fieldAccessMeta(access);
				var value = metaStringParam(meta, ":deviseHxSanitizerAction");
				if (value == null) {
					Context.error("DeviseParams.permit expects a typed SanitizerAction such as SanitizerAction.signUp.", expr.pos);
				}
				validateName(value, "Devise sanitizer action", expr.pos);
				value;
			case _:
				Context.error("DeviseParams.permit expects a typed SanitizerAction such as SanitizerAction.signUp.", expr.pos);
		}
	}

	public static function signInOptions(options:Null<Expr>):Array<DeviseSignInOption> {
		if (options == null) {
			return [];
		}
		var byName = new Map<String, Expr>();
		switch unwrapExpr(options).expr {
			case EConst(CIdent("null")) | EBlock([]):
				return [];
			case EObjectDecl(fields):
				for (field in fields) {
					if (field.field != "force" && field.field != "store") {
						Context.error('Auth.signIn unsupported option "${field.field}". Supported options are force and store; use bypassSignIn(...) for bypass behavior.',
							field.expr.pos);
					}
					if (byName.exists(field.field)) {
						Context.error('Auth.signIn option "${field.field}" is duplicated.', field.expr.pos);
					}
					requireBool(field.expr, 'Auth.signIn option "${field.field}"');
					byName.set(field.field, field.expr);
				}
			case _:
				Context.error("Auth.signIn options must be an object literal so DeviseHx can preserve a checked Ruby keyword shape.", options.pos);
		}
		return [
			for (name in ["force", "store"])
				if (byName.exists(name)) {name: name, value: byName.get(name)}
		];
	}

	public static function sanitizerKeys(expr:Expr, allowStrings:Bool, contract:DeviseRouteContract):Array<String> {
		var typed = Context.typeExpr(expr);
		return switch (unwrapTyped(typed).expr) {
			case TArrayDecl(values):
				[for (value in values) sanitizerKey(value, allowStrings, contract)];
			case _:
				Context.error("DeviseParams.permit keys must be an array literal of generated model field refs.", expr.pos);
		}
	}

	public static function requireDeviseResource(expr:Expr):Void {
		var followed = TypeTools.follow(Context.typeof(expr));
		var classType = switch followed {
			case TInst(ref, _): ref.get();
			case _:
				Context.error("DeviseErrors expects a typed Devise resource.", expr.pos);
		}
		if (!implementsInterface(classType, "devisehx.model.DeviseResource")) {
			Context.error("DeviseErrors expects a model implementing DeviseResource.", expr.pos);
		}
	}

	public static function rubySymbol(value:String):String {
		return ":" + value;
	}

	static function sanitizerKey(expr:TypedExpr, allowStrings:Bool, contract:DeviseRouteContract):String {
		return switch (unwrapTyped(expr).expr) {
			case TField(_, access):
				var name = metaStringParam(fieldAccessMeta(access), ":railsField");
				if (name == null) {
					Context.error("DeviseParams.permit keys must use generated RailsHx model field refs such as User.f.name.", expr.pos);
				}
				var owner = activeRecordFieldModel(expr.t);
				if (owner != null && contract.haxeModel != "" && owner != contract.haxeModel) {
					Context.error("DeviseParams.permit field model " + owner + " should be " + contract.haxeModel + ".", expr.pos);
				}
				name;
			case TConst(TString(value)) if (allowStrings):
				validateName(value, "DeviseParams.unsafePermit key", expr.pos);
				value;
			case TConst(TString(_)):
				Context.error("DeviseParams.permit keys must use generated RailsHx model field refs; use unsafePermit(...) for reviewed custom string keys.",
					expr.pos);
			case _:
				Context.error(allowStrings ? "DeviseParams.unsafePermit keys must be literal strings." : "DeviseParams.permit keys must use generated RailsHx model field refs such as User.f.name.",
					expr.pos);
		}
	}

	static function requireBool(expr:Expr, label:String):Void {
		switch TypeTools.follow(Context.typeof(expr)) {
			case TAbstract(ref, _) if (fullTypeName(ref.get().pack, ref.get().name) == "Bool"):
			case _:
				Context.error(label + " must be Bool.", expr.pos);
		}
	}

	static function activeRecordFieldModel(type:Type):Null<String> {
		return switch (TypeTools.follow(type)) {
			case TAbstract(ref, params):
				var name = fullTypeName(ref.get().pack, ref.get().name);
				if ((name == "rails.active_record.Field" || name == "rails.active_record.NullableField") && params.length > 0) {
					typeName(params[0]);
				} else {
					null;
				}
			case _:
				null;
		}
	}

	static function scopeModelType(type:Type, pos:Position):Type {
		return switch (TypeTools.follow(type)) {
			case TInst(ref, params) if (fullTypeName(ref.get().pack, ref.get().name) == "devisehx.DeviseScope" && params.length == 1):
				params[0];
			case _:
				Context.error("Generated Devise scope metadata must annotate a DeviseScope<TModel> field.", pos);
		}
	}

	static function staticFieldInfo(typed:TypedExpr):Null<StaticFieldInfo> {
		return switch (unwrapTyped(typed).expr) {
			case TField(_, FStatic(owner, field)):
				var type = owner.get();
				{typeName: fullTypeName(type.pack, type.name), fieldName: field.get().name, field: field.get()};
			case _:
				null;
		}
	}

	static function routeMeta(field:ClassField):Null<MetadataEntry> {
		for (entry in field.meta.get()) {
			if (entry.name == ":deviseHxRoute") {
				return entry;
			}
		}
		return null;
	}

	static function parseContractMeta(meta:MetadataEntry, pos:Position):DeviseRouteContract {
		if (meta.params.length != 1) {
			Context.error("@:deviseHxRoute expects one object-literal metadata argument.", pos);
		}
		var contract:DeviseRouteContract = {
			schema: 0,
			routeAuthorable: false,
			resource: "",
			mappingScope: "",
			rubyClass: "",
			haxeModel: "",
			reason: "",
			contractType: "",
			contractField: "",
			modelType: Context.typeof(macro null)
		};
		switch meta.params[0].expr {
			case EObjectDecl(fields):
				for (field in fields) {
					switch field.field {
						case "schema": contract.schema = intLiteral(field.expr, "schema");
						case "routeAuthorable": contract.routeAuthorable = boolLiteral(field.expr, "routeAuthorable");
						case "resource": contract.resource = stringLiteral(field.expr, "resource");
						case "mappingScope": contract.mappingScope = stringLiteral(field.expr, "mappingScope");
						case "rubyClass": contract.rubyClass = stringLiteral(field.expr, "rubyClass");
						case "haxeModel": contract.haxeModel = stringLiteral(field.expr, "haxeModel");
						case "reason": contract.reason = stringLiteral(field.expr, "reason");
						case other: Context.error("Unsupported @:deviseHxRoute metadata key " + other + ".", field.expr.pos);
					}
				}
			case _:
				Context.error("@:deviseHxRoute metadata must be an object literal.", pos);
		}
		return contract;
	}

	static function intLiteral(expr:Expr, label:String):Int {
		return switch expr.expr {
			case EConst(CInt(value)): Std.parseInt(value);
			case _: Context.error("@:deviseHxRoute " + label + " must be an integer literal.", expr.pos);
		}
	}

	static function boolLiteral(expr:Expr, label:String):Bool {
		return switch expr.expr {
			case EConst(CIdent("true")): true;
			case EConst(CIdent("false")): false;
			case _: Context.error("@:deviseHxRoute " + label + " must be a boolean literal.", expr.pos);
		}
	}

	static function stringLiteral(expr:Expr, label:String):String {
		return switch expr.expr {
			case EConst(CString(value)): value;
			case _: Context.error("@:deviseHxRoute " + label + " must be a string literal.", expr.pos);
		}
	}

	static function fieldAccessMeta(access:FieldAccess):Null<MetaAccess> {
		return switch access {
			case FInstance(_, _, field) | FStatic(_, field): field.get().meta;
			case FAnon(fieldRef) | FClosure(_, fieldRef): fieldRef.get().meta;
			case FEnum(_, field): field.meta;
			case FDynamic(_): null;
		}
	}

	static function metaStringParam(meta:Null<MetaAccess>, name:String):Null<String> {
		if (meta == null) {
			return null;
		}
		var entries = meta.extract(name);
		if (entries.length == 0 || entries[0].params.length != 1) {
			return null;
		}
		return switch entries[0].params[0].expr {
			case EConst(CString(value)): value;
			case _: null;
		}
	}

	static function implementsInterface(classType:ClassType, expected:String):Bool {
		for (entry in classType.interfaces) {
			var iface = entry.t.get();
			if (fullTypeName(iface.pack, iface.name) == expected || implementsInterface(iface, expected)) {
				return true;
			}
		}
		return classType.superClass != null && implementsInterface(classType.superClass.t.get(), expected);
	}

	static function validateName(value:String, label:String, pos:Position):Void {
		if (!~/^[a-z][a-z0-9_]*$/.match(value)) {
			Context.error(label + " must be a safe snake_case Rails symbol.", pos);
		}
	}

	static function validateRubyClass(value:String, pos:Position):Void {
		if (!~/^[A-Z][A-Za-z0-9_]*(::[A-Z][A-Za-z0-9_]*)*$/.match(value)) {
			Context.error("Devise rubyClass metadata must be a safe Ruby constant path.", pos);
		}
	}

	static function validateHaxeModel(type:Type, expected:String, pos:Position):Void {
		var actual = typeName(type);
		if (expected != "" && actual != null && actual != expected) {
			Context.error("Devise route contract model mismatch: metadata describes "
				+ expected
				+ " but field type is DeviseScope<"
				+ actual
				+ ">.", pos);
		}
	}

	static function typeName(type:Type):Null<String> {
		return switch (TypeTools.follow(type)) {
			case TInst(ref, _): fullTypeName(ref.get().pack, ref.get().name);
			case _: null;
		}
	}

	static function unwrapTyped(expr:TypedExpr):TypedExpr {
		return switch expr.expr {
			case TParenthesis(inner) | TMeta(_, inner): unwrapTyped(inner);
			case _: expr;
		}
	}

	static function unwrapExpr(expr:Expr):Expr {
		return switch expr.expr {
			case EParenthesis(inner) | EMeta(_, inner): unwrapExpr(inner);
			case _: expr;
		}
	}

	static function fullTypeName(pack:Array<String>, name:String):String {
		return pack.length == 0 ? name : pack.join(".") + "." + name;
	}
}
#else
class ContractTools {}
#end
