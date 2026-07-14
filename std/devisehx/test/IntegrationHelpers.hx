package devisehx.test;

#if macro
import devisehx.macros.ContractTools;
import haxe.macro.Expr;
#end

/**
	Typed Devise test helpers for Haxe-authored Rails tests.

	Vanilla Rails/Minitest/RSpec remains first-class. These helpers let generated
	Haxe-authored tests reuse typed Devise scopes before the compiler lowers them
	to normal Devise test helper calls such as `sign_in(:user, user)`. The scope
	must be a direct generated field like `UserAuth.scope` so the compiler can
	read the metadata without evaluating runtime Haxe values.

	`@:rubyNoEmit` keeps the helper surface Haxe-only; generated tests call
	Devise's own integration helpers directly.
**/
@:rubyNoEmit
class IntegrationHelpers {
	public static macro function signIn(scope:Expr, resource:Expr):Expr {
		#if macro
		var contract = ContractTools.routeContract(scope, "IntegrationHelpers.signIn");
		ContractTools.requireModel(resource, contract, "IntegrationHelpers.signIn");
		return macro @:pos(scope.pos) devisehx.macros.RubyFragments.testVoid1($v{
			"sign_in(" + ContractTools.rubySymbol(contract.mappingScope) + ", {0})"
		}, $resource);
		#else
		return macro null;
		#end
	}

	public static macro function signOut(scope:Expr):Expr {
		#if macro
		var contract = ContractTools.routeContract(scope, "IntegrationHelpers.signOut");
		return macro @:pos(scope.pos) devisehx.macros.RubyFragments.testVoid0($v{
			"sign_out(" + ContractTools.rubySymbol(contract.mappingScope) + ")"
		});
		#else
		return macro null;
		#end
	}
}
