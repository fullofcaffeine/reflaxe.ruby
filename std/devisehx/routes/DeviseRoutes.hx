package devisehx.routes;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.MetadataEntry;
import haxe.macro.Expr.Position;
import haxe.macro.Type;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.TypedExpr;
#end

/**
	Devise route declarations for Haxe-owned route files.

	Rails-owned `devise_for` is supported through `rails routes` route extern
	generation. For Haxe-owned routes, this macro accepts only generated
	`UserAuth.scope`-style static fields carrying DeviseHx route metadata, then
	lowers to a compiler marker that emits ordinary Rails `devise_for :users`.

	`@:rubyNoEmit` keeps this macro facade out of Ruby output because the emitted
	artifact is a Rails route declaration, not a DeviseHx runtime object.
**/
@:rubyNoEmit
class DeviseRoutes {
	public static macro function deviseFor(scope:Expr, ?options:Expr):Expr {
		#if macro
		var contract = generatedRouteContract(scope);
		var routeOptions = deviseRouteOptions(options);
		return macro @:pos(scope.pos) rails.routing.RouteDecl.deviseFor($v{contract.resource}, $v{contract.mappingScope}, $v{contract.rubyClass},
			$v{contract.contractType}, $v{contract.contractField}, $v{contract.schema}, $e{stringArray(routeOptions.only, scope.pos)},
			$e{stringArray(routeOptions.skip, scope.pos)});
		#else
		return macro null;
		#end
	}

	#if macro
	static function deviseRouteOptions(options:Null<Expr>):DeviseRouteOptions {
		if (options == null || isNullExpr(options)) {
			return {only: [], skip: []};
		}
		var out:DeviseRouteOptions = {only: [], skip: []};
		switch unwrap(options).expr {
			case EObjectDecl(fields):
				for (field in fields) {
					switch field.field {
						case "only":
							out.only = routeGroupArray(field.expr, "only");
						case "skip":
							out.skip = routeGroupArray(field.expr, "skip");
						case other:
							Context.error('DeviseRoutes.deviseFor unsupported option "$other". Supported options are only and skip.', field.expr.pos);
					}
				}
			case _:
				Context.error("DeviseRoutes.deviseFor options must be an object literal.", options.pos);
		}
		if (out.only.length > 0 && out.skip.length > 0) {
			Context.error("DeviseRoutes.deviseFor cannot combine only and skip. Split the declarations explicitly or keep this Devise route Rails-owned.",
				options.pos);
		}
		return out;
	}

	static function routeGroupArray(expr:Expr, label:String):Array<String> {
		return switch unwrap(expr).expr {
			case EArrayDecl(values):
				if (values.length == 0) {
					Context.error('DeviseRoutes.deviseFor $label must include at least one DeviseRouteGroup token.', expr.pos);
				}
				[for (value in values) routeGroup(value, label)];
			case _:
				Context.error('DeviseRoutes.deviseFor $label must be an array of DeviseRouteGroup tokens.', expr.pos);
				[];
		}
	}

	static function routeGroup(expr:Expr, label:String):String {
		var typed = Context.typeExpr(expr);
		var token = switch typed.expr {
			case TField(_, FEnum(enumRef, enumField)):
				var enumType = enumRef.get();
				if (fullTypeName(enumType.pack, enumType.name) != "devisehx.routes.DeviseRouteGroup") {
					Context.error('DeviseRoutes.deviseFor $label entries must come from devisehx.routes.DeviseRouteGroup.', expr.pos);
				}
				enumField.name;
			case _:
				Context.error('DeviseRoutes.deviseFor $label entries must be DeviseRouteGroup enum tokens, not strings or dynamic values.', expr.pos);
				"";
		}
		return switch token {
			case "Sessions":
				"sessions";
			case "Passwords":
				"passwords";
			case "Registrations":
				"registrations";
			case "Confirmations":
				"confirmations";
			case "Unlocks":
				"unlocks";
			case "OmniauthCallbacks":
				"omniauth_callbacks";
			case _:
				Context.error('Unsupported DeviseRouteGroup "$token" in DeviseRoutes.deviseFor $label.', expr.pos);
				"";
		}
	}

	static function stringArray(values:Array<String>, pos:Position):Expr {
		return {
			expr: EArrayDecl([for (value in values) macro $v{value}]),
			pos: pos
		};
	}

	static function unwrap(expr:Expr):Expr {
		return switch expr.expr {
			case EParenthesis(inner) | EMeta(_, inner): unwrap(inner);
			case _: expr;
		}
	}

	static function isNullExpr(expr:Expr):Bool {
		return switch unwrap(expr).expr {
			case EConst(CIdent("null")): true;
			case _: false;
		}
	}

	static function generatedRouteContract(scope:Expr):DeviseRouteContract {
		var typed = Context.typeExpr(scope);
		var fieldInfo = staticFieldInfo(typed);
		if (fieldInfo == null) {
			Context.error("DeviseRoutes.deviseFor expects a direct generated Devise scope field such as UserAuth.scope; runtime DeviseScope values, locals, function calls, and constructed scopes cannot be inspected safely.",
				scope.pos);
		}
		var meta = routeMeta(fieldInfo.field);
		if (meta == null) {
			Context.error("DeviseRoutes.deviseFor expected a generated DeviseHx route contract on "
				+ fieldInfo.typeName
				+ "."
				+ fieldInfo.fieldName
				+ ". Regenerate the DeviseHx contract or keep this route Rails-owned.",
				scope.pos);
		}
		var contract = parseContractMeta(meta, scope.pos);
		if (contract.schema != 1) {
			Context.error("Unsupported DeviseHx route contract schema " + contract.schema + " on " + fieldInfo.typeName + "." + fieldInfo.fieldName
				+ ". Regenerate the contract with the current toolchain.",
				scope.pos);
		}
		if (!contract.routeAuthorable) {
			Context.error("DeviseRoutes.deviseFor cannot author this adopted Devise route"
				+ (contract.reason == "" ? "." : ": " + contract.reason), scope.pos);
		}
		contract.contractType = fieldInfo.typeName;
		contract.contractField = fieldInfo.fieldName;
		validateName(contract.resource, "Devise route resource", scope.pos);
		validateName(contract.mappingScope, "Devise mapping scope", scope.pos);
		validateRubyClass(contract.rubyClass, scope.pos);
		validateHaxeModel(typed.t, contract.haxeModel, scope.pos);
		return contract;
	}

	static function staticFieldInfo(typed:TypedExpr):Null<StaticFieldInfo> {
		return switch typed.expr {
			case TParenthesis(inner) | TMeta(_, inner): staticFieldInfo(inner);
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
			contractField: ""
		};
		switch meta.params[0].expr {
			case EObjectDecl(fields):
				for (field in fields) {
					switch field.field {
						case "schema":
							contract.schema = intLiteral(field.expr, "schema");
						case "routeAuthorable":
							contract.routeAuthorable = boolLiteral(field.expr, "routeAuthorable");
						case "resource":
							contract.resource = stringLiteral(field.expr, "resource");
						case "mappingScope":
							contract.mappingScope = stringLiteral(field.expr, "mappingScope");
						case "rubyClass":
							contract.rubyClass = stringLiteral(field.expr, "rubyClass");
						case "haxeModel":
							contract.haxeModel = stringLiteral(field.expr, "haxeModel");
						case "reason":
							contract.reason = stringLiteral(field.expr, "reason");
						case other:
							Context.error("Unsupported @:deviseHxRoute metadata key " + other + ".", field.expr.pos);
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
		if (expected == "") {
			return;
		}
		var actual = switch type {
			case TInst(_.get() => _, [TInst(_.get() => model, _)]):
				fullTypeName(model.pack, model.name);
			case _:
				"";
		}
		if (actual != "" && actual != expected) {
			Context.error("Devise route contract model mismatch: metadata describes "
				+ expected
				+ " but field type is DeviseScope<"
				+ actual
				+ ">.", pos);
		}
	}

	static function fullTypeName(pack:Array<String>, name:String):String {
		return pack.length == 0 ? name : pack.join(".") + "." + name;
	}
	#end
}

#if macro
private typedef StaticFieldInfo = {
	final typeName:String;
	final fieldName:String;
	final field:ClassField;
}

private typedef DeviseRouteContract = {
	var schema:Int;
	var routeAuthorable:Bool;
	var resource:String;
	var mappingScope:String;
	var rubyClass:String;
	var haxeModel:String;
	var reason:String;
	var contractType:String;
	var contractField:String;
}

private typedef DeviseRouteOptions = {
	var only:Array<String>;
	var skip:Array<String>;
}
#end
