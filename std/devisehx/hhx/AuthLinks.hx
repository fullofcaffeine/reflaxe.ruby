package devisehx.hhx;

#if macro
import devisehx.macros.ContractTools;
import haxe.macro.Expr;
#end

/**
	Typed Devise route helpers for Rails HHX templates. The companion macro reads
	the generated scope contract and hands a validated literal Rails helper call
	to the compiler's generic extension-expression carrier.
**/
@:rubyNoEmit
class AuthLinks {
	public static macro function newSessionPath(scope:Expr):Expr {
		return path(scope, "new_", "_session_path");
	}

	public static macro function sessionPath(scope:Expr):Expr {
		return path(scope, "", "_session_path");
	}

	public static macro function destroySessionPath(scope:Expr):Expr {
		return path(scope, "destroy_", "_session_path");
	}

	public static macro function newRegistrationPath(scope:Expr):Expr {
		return path(scope, "new_", "_registration_path");
	}

	public static macro function editRegistrationPath(scope:Expr):Expr {
		return path(scope, "edit_", "_registration_path");
	}

	public static macro function registrationPath(scope:Expr):Expr {
		return path(scope, "", "_registration_path");
	}

	public static macro function cancelRegistrationPath(scope:Expr):Expr {
		return path(scope, "cancel_", "_registration_path");
	}

	public static macro function newPasswordPath(scope:Expr):Expr {
		return path(scope, "new_", "_password_path");
	}

	public static macro function editPasswordPath(scope:Expr):Expr {
		return path(scope, "edit_", "_password_path");
	}

	public static macro function passwordPath(scope:Expr):Expr {
		return path(scope, "", "_password_path");
	}

	public static macro function newConfirmationPath(scope:Expr):Expr {
		return path(scope, "new_", "_confirmation_path");
	}

	public static macro function confirmationPath(scope:Expr):Expr {
		return path(scope, "", "_confirmation_path");
	}

	public static macro function newUnlockPath(scope:Expr):Expr {
		return path(scope, "new_", "_unlock_path");
	}

	public static macro function unlockPath(scope:Expr):Expr {
		return path(scope, "", "_unlock_path");
	}

	public static macro function signInPath(scope:Expr):Expr {
		return path(scope, "new_", "_session_path");
	}

	public static macro function signOutPath(scope:Expr):Expr {
		return path(scope, "destroy_", "_session_path");
	}

	public static macro function signUpPath(scope:Expr):Expr {
		return path(scope, "new_", "_registration_path");
	}

	#if macro
	static function path(scope:Expr, prefix:String, suffix:String):Expr {
		var contract = ContractTools.routeContract(scope, "AuthLinks");
		var call = macro @:pos(scope.pos) devisehx.macros.RubyFragments.value0($v{prefix + contract.mappingScope + suffix + "()"});
		return ContractTools.checked(call, macro :String);
	}
	#end
}
