package reflaxe.ruby.rails;

#if (macro || reflaxe_runtime)
typedef RailsRouteTarget = {
	controller:String,
	action:String
}
#end
