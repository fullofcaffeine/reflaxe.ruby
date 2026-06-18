package reflaxe.ruby.rails;

#if (macro || reflaxe_runtime)
import haxe.macro.Expr.Position;

typedef RailsRouteDecl = {
	kind:String,
	target:Null<RailsRouteTarget>,
	verb:String,
	verbs:Array<String>,
	path:String,
	name:String,
	controller:String,
	moduleName:String,
	only:Array<String>,
	except:Array<String>,
	param:String,
	options:Array<String>,
	children:Array<RailsRouteDecl>,
	pos:Position
}
#end
