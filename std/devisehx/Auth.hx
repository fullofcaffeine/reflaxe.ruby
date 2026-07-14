package devisehx;

#if macro
import devisehx.macros.ContractTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.ExprOf;
#end

/**
	Typed facade over Devise controller helpers.

	These methods are compiler/generator contracts: Rails/Devise owns the runtime
	helpers (`current_user`, `user_signed_in?`, `sign_in`, `sign_out`). RailsHx
	uses the scope token to make those calls type-safe from Haxe.

	`@:rubyNoEmit` marks this as a compile-time facade: the compiler lowers calls
	to ordinary Devise helpers and does not emit a DeviseHx Ruby runtime class.
**/
@:rubyNoEmit
class Auth {
	public static function require<TModel>(scope:DeviseScope<TModel>):AuthFilter<TModel> {
		return AuthFilter.forScope(scope);
	}

	public static macro function current(controller:Expr, scope:Expr):Expr {
		#if macro
		var contract = ContractTools.routeContract(scope, "Auth.current");
		return ContractTools.checked(macro @:pos(scope.pos) devisehx.macros.RubyFragments.value0($v{"current_" + contract.mappingScope + "()"}),
			ContractTools.nullableModelComplexType(contract));
		#else
		return macro null;
		#end
	}

	public static macro function currentRequired(controller:Expr, scope:Expr):Expr {
		#if macro
		var contract = ContractTools.routeContract(scope, "Auth.currentRequired");
		var filter = "authenticate_" + contract.mappingScope + "!";
		return ContractTools.checked(macro @:pos(scope.pos) devisehx.macros.RubyFragments.requiredValue0($v{filter},
			$v{"current_" + contract.mappingScope + "()"}),
			ContractTools.modelComplexType(contract));
		#else
		return macro null;
		#end
	}

	public static macro function signedIn(controller:Expr, scope:Expr):Expr {
		#if macro
		var contract = ContractTools.routeContract(scope, "Auth.signedIn");
		return ContractTools.checked(macro @:pos(scope.pos) devisehx.macros.RubyFragments.value0($v{contract.mappingScope + "_signed_in?()"}), macro :Bool);
		#else
		return macro null;
		#end
	}

	public static macro function signIn(controller:Expr, scope:Expr, resource:Expr, ?options:ExprOf<SignInOptions>):Expr {
		#if macro
		var contract = ContractTools.routeContract(scope, "Auth.signIn");
		ContractTools.requireModel(resource, contract, "Auth.signIn");
		var parsedOptions = ContractTools.signInOptions(options);
		var template = "sign_in(" + ContractTools.rubySymbol(contract.mappingScope) + ", {0}";
		for (index in 0...parsedOptions.length) {
			template += ", " + parsedOptions[index].name + ": {" + (index + 1) + "}";
		}
		template += ")";
		return switch parsedOptions.length {
			case 0:
				macro @:pos(scope.pos) devisehx.macros.RubyFragments.void1($v{template}, $resource);
			case 1:
				var value = parsedOptions[0].value;
				macro @:pos(scope.pos) devisehx.macros.RubyFragments.void2($v{template}, $resource, $value);
			case 2:
				var first = parsedOptions[0].value;
				var second = parsedOptions[1].value;
				macro @:pos(scope.pos) devisehx.macros.RubyFragments.void3($v{template}, $resource, $first, $second);
			case _:
				Context.error("Auth.signIn internal option arity exceeded the checked SignInOptions contract.", scope.pos);
		};
		#else
		return macro null;
		#end
	}

	public static macro function bypassSignIn(controller:Expr, scope:Expr, resource:Expr):Expr {
		#if macro
		var contract = ContractTools.routeContract(scope, "Auth.bypassSignIn");
		ContractTools.requireModel(resource, contract, "Auth.bypassSignIn");
		return macro @:pos(scope.pos) devisehx.macros.RubyFragments.void1($v{
			"bypass_sign_in({0}, scope: " + ContractTools.rubySymbol(contract.mappingScope) + ")"
		}, $resource);
		#else
		return macro null;
		#end
	}

	public static macro function signOut(controller:Expr, scope:Expr):Expr {
		#if macro
		var contract = ContractTools.routeContract(scope, "Auth.signOut");
		return macro @:pos(scope.pos) devisehx.macros.RubyFragments.void0($v{"sign_out(" + ContractTools.rubySymbol(contract.mappingScope) + ")"});
		#else
		return macro null;
		#end
	}

	public static macro function signOutAll(controller:Expr):Expr {
		return macro @:pos(controller.pos) devisehx.macros.RubyFragments.void0("sign_out_all_scopes()");
	}
}
