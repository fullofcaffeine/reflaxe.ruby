package rails.action_controller;

/**
	Compiler-owned marker calls for controller lifecycle declarations.

	`rails.macros.ControllerDsl` expands user-friendly declarations such as
	`beforeAction(authenticateUser)` into these typed calls. The Ruby compiler
	recognizes them only inside a controller `lifecycle` block and erases them
	into Rails class macros, so no RailsHx runtime DSL is introduced.
**/
extern class LifecycleDecl {
	public static function filter(kind:String, method:String, only:Array<String>, except:Array<String>):LifecycleDecl;

	public static function rescue(method:String, exceptions:Array<String>):LifecycleDecl;

	public static function protectFromForgery(strategy:String, prepend:Bool, only:Array<String>, except:Array<String>):LifecycleDecl;
}
