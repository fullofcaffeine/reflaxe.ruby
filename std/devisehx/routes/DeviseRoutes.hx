package devisehx.routes;

#if macro
import devisehx.macros.ContractTools;
import devisehx.macros.ContractTools.DeviseRouteContract;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
#end

/**
	Devise route declarations for Haxe-owned route files. DeviseHx validates the
	generated scope and options, then emits the compiler's generic opaque route
	extension marker with ordinary Rails source and a versioned manifest object.
**/
@:rubyNoEmit
class DeviseRoutes {
	public static macro function deviseFor(scope:Expr, ?options:Expr):Expr {
		#if macro
		var contract = ContractTools.routeContract(scope, "DeviseRoutes.deviseFor");
		ContractTools.requireAuthorable(contract, scope.pos);
		var routeOptions = deviseRouteOptions(options);
		var parts = ["devise_for " + ContractTools.rubySymbol(contract.resource)];
		if (contract.rubyClass.indexOf("::") >= 0) {
			parts.push("class_name: " + haxe.Json.stringify(contract.rubyClass));
		}
		if (routeOptions.only.length > 0) {
			parts.push("only: [" + [for (group in routeOptions.only) ContractTools.rubySymbol(group)].join(", ") + "]");
		}
		if (routeOptions.skip.length > 0) {
			parts.push("skip: [" + [for (group in routeOptions.skip) ContractTools.rubySymbol(group)].join(", ") + "]");
		}
		var signature = "only=" + routeOptions.only.join(",") + "|skip=" + routeOptions.skip.join(",");
		var split = routeOptions.only.length > 0 || routeOptions.skip.length > 0;
		var manifest = manifestJson(contract, routeOptions);
		return macro @:pos(scope.pos) rails.routing.RouteDecl.extension("Devise route", $v{parts.join(", ")}, $v{manifest}, true, $v{contract.mappingScope},
			$v{signature}, $v{split});
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
						case "only": out.only = routeGroupArray(field.expr, "only");
						case "skip": out.skip = routeGroupArray(field.expr, "skip");
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
		}
		return switch token {
			case "Sessions": "sessions";
			case "Passwords": "passwords";
			case "Registrations": "registrations";
			case "Confirmations": "confirmations";
			case "Unlocks": "unlocks";
			case "OmniauthCallbacks": "omniauth_callbacks";
			case _:
				Context.error('Unsupported DeviseRouteGroup "$token" in DeviseRoutes.deviseFor $label.', expr.pos);
		}
	}

	static function manifestJson(contract:DeviseRouteContract, options:DeviseRouteOptions):String {
		var optionFields:Array<String> = [];
		if (options.only.length > 0) {
			optionFields.push('"only":' + haxe.Json.stringify(options.only));
		}
		if (options.skip.length > 0) {
			optionFields.push('"skip":' + haxe.Json.stringify(options.skip));
		}
		return "{"
			+ '"options":{${optionFields.join(",")}},'
			+ '"position":"__railshx_position__",'
			+
			'"contract":{"schema":${contract.schema},"field":${haxe.Json.stringify(contract.contractField)},"type":${haxe.Json.stringify(contract.contractType)}},'
			+
			'"expectedMapping":{"name":${haxe.Json.stringify(contract.mappingScope)},"path":${haxe.Json.stringify(contract.resource)},"className":${haxe.Json.stringify(contract.rubyClass)}},'
			+ '"kind":"deviseFor",'
			+ '"resource":${haxe.Json.stringify(contract.resource)}'
			+ "}";
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

	static function fullTypeName(pack:Array<String>, name:String):String {
		return pack.length == 0 ? name : pack.join(".") + "." + name;
	}
	#end
}

#if macro
private typedef DeviseRouteOptions = {
	var only:Array<String>;
	var skip:Array<String>;
}
#end
