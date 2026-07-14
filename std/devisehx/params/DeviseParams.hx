package devisehx.params;

#if macro
import devisehx.macros.ContractTools;
import haxe.macro.Expr;
#end

/**
	Typed facade for Devise's `devise_parameter_sanitizer.permit(...)`.

	`permit(...)` accepts generated RailsHx model field refs such as `User.f.name`,
	so Haxe verifies the field owner matches the Devise scope model. The compiler
	erases the facade to normal Devise/Rails Ruby:
	`devise_parameter_sanitizer.permit(:sign_up, keys: [:name])`.

	`@:rubyNoEmit` marks this as an erased typed facade; runtime behavior remains
	Devise's parameter sanitizer, not a generated DeviseHx Ruby class.
**/
@:rubyNoEmit
class DeviseParams {
	public static macro function permit(scope:Expr, action:Expr, keys:Expr):Expr {
		#if macro
		var contract = ContractTools.routeContract(scope, "DeviseParams.permit");
		var actionName = ContractTools.sanitizerAction(action);
		var keyNames = ContractTools.sanitizerKeys(keys, false, contract);
		var code = "devise_parameter_sanitizer.permit("
			+ ContractTools.rubySymbol(actionName)
			+ ", keys: ["
			+ [for (key in keyNames) ContractTools.rubySymbol(key)].join(", ") + "])";
		return macro @:pos(scope.pos) devisehx.macros.RubyFragments.void0($v{code});
		#else
		return macro null;
		#end
	}

	/**
		Explicit escape hatch for custom Devise sanitizer keys that are not known
		as typed model fields yet. The compiler accepts literal strings only and
		still emits normal Devise Ruby. Prefer `permit(...)` whenever schema/model
		metadata can generate a field ref.
	**/
	public static macro function unsafePermit(scope:Expr, action:Expr, keys:Expr):Expr {
		#if macro
		var contract = ContractTools.routeContract(scope, "DeviseParams.unsafePermit");
		var actionName = ContractTools.sanitizerAction(action);
		var keyNames = ContractTools.sanitizerKeys(keys, true, contract);
		var code = "devise_parameter_sanitizer.permit("
			+ ContractTools.rubySymbol(actionName)
			+ ", keys: ["
			+ [for (key in keyNames) ContractTools.rubySymbol(key)].join(", ") + "])";
		return macro @:pos(scope.pos) devisehx.macros.RubyFragments.void0($v{code});
		#else
		return macro null;
		#end
	}
}
