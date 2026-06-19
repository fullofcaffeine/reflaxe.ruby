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
		validateDeviseForLocations(decls, true);
		validateDeviseMappings(decls);
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

	static function validateDeviseForLocations(decls:Array<RailsRouteDecl>, topLevel:Bool):Void {
		for (decl in decls) {
			if (decl.kind == "deviseFor" && !topLevel) {
				Context.error("@:railsRoutes DeviseRoutes.deviseFor(...) is top-level only in this MVP. Keep nested/scoped/custom Devise routes Rails-owned until typed Devise route options land.",
					decl.pos);
			}
			if (decl.children.length > 0) {
				validateDeviseForLocations(decl.children, false);
			}
		}
	}

	static function validateDeviseMappings(decls:Array<RailsRouteDecl>):Void {
		var seen = new Map<String, Position>();
		validateDeviseMappingsIn(decls, seen);
	}

	static function validateDeviseMappingsIn(decls:Array<RailsRouteDecl>, seen:Map<String, Position>):Void {
		for (decl in decls) {
			if (decl.kind == "deviseFor" && decl.devise != null) {
				var key = decl.devise.mappingScope;
				if (seen.exists(key)) {
					Context.error('@:railsRoutes duplicate Devise mapping scope "${key}". Split Devise route mappings are planned, but require typed only/skip route options first (tracked by haxe.ruby-443); keep split/custom Devise routes Rails-owned for the MVP.',
						decl.pos);
				}
				seen.set(key, decl.pos);
			}
			if (decl.children.length > 0) {
				validateDeviseMappingsIn(decl.children, seen);
			}
		}
	}
}
#end
