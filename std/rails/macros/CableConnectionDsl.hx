package rails.macros;

#if macro
import haxe.macro.Expr;
#else
import rails.action_cable.ConnectionDecl;
import rails.action_cable.ConnectionIdentifier;
#end

/**
	Typed ActionCable connection declarations.

	Like Rails controller/job lifecycle blocks, this DSL stays valid Haxe:

	```haxe
	static final identifiers = {
		identifiedBy(currentUser);
	}
	```

	The call expands to a compiler marker that the Ruby backend erases into
	Rails' native `identified_by :current_user` class macro.
**/
class CableConnectionDsl {
	public static macro function identifiedBy(identifier:Expr):Expr {
		return macro rails.action_cable.ConnectionDecl.identifiedBy($identifier);
	}
}
