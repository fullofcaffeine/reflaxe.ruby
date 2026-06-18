package rails.routing;

/**
	Compiler-owned Rails route declaration carrier.

	These functions are not a runtime routing DSL. `rails.macros.RoutesDsl`
	expands friendly Haxe calls into these marker calls, and `reflaxe.ruby`
	lowers them into normal Rails `config/routes.rb` statements.
**/
extern class RouteDecl {
	public static function root(target:RouteTarget):RouteDecl;

	public static function verb(method:String, path:String, target:RouteTarget, name:String):RouteDecl;

	public static function resources(name:String, controller:String, only:Array<String>, except:Array<String>, param:String,
		children:Array<RouteDecl>):RouteDecl;

	public static function resource(name:String, controller:String, only:Array<String>, except:Array<String>, param:String,
		children:Array<RouteDecl>):RouteDecl;

	public static function collection(children:Array<RouteDecl>):RouteDecl;

	public static function member(children:Array<RouteDecl>):RouteDecl;
}
