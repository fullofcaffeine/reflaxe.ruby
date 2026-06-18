package reflaxe.ruby.rails;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Expr.Position;

/**
	Route IR validation that sits between typed Haxe marker extraction and Rails
	emission. The typed-expression walk still lives in `RubyCompiler` for now, but
	cross-route checks belong here so route semantics can grow outside the
	compiler core.
**/
class RailsRoutesExtractor {
	public static function validateTopLevel(decls:Array<RailsRouteDecl>):Void {
		for (decl in decls) {
			if (decl.kind == "collection" || decl.kind == "member") {
				Context.error('@:railsRoutes ${decl.kind} blocks must be nested inside resources/resource declarations.', decl.pos);
			}
		}
	}

	public static function validateAliases(decls:Array<RailsRouteDecl>):Void {
		var seen = new Map<String, Position>();
		validateAliasesIn(decls, seen);
	}

	static function validateAliasesIn(decls:Array<RailsRouteDecl>, seen:Map<String, Position>):Void {
		for (decl in decls) {
			if (decl.name != "" && ["verb", "match", "mount"].indexOf(decl.kind) != -1) {
				if (seen.exists(decl.name)) {
					Context.error('@:railsRoutes duplicate explicit route alias "${decl.name}". Each asName must be unique within a Haxe-owned routes file.',
						decl.pos);
				}
				seen.set(decl.name, decl.pos);
			}
			if (decl.children.length > 0) {
				validateAliasesIn(decl.children, seen);
			}
		}
	}
}
#end
