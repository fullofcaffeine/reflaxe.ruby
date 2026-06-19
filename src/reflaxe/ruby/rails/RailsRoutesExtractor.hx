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
		var splitByScope = new Map<String, Bool>();
		var signatureByScope = new Map<String, Position>();
		validateDeviseMappingsIn(decls, splitByScope, signatureByScope);
	}

	static function validateDeviseMappingsIn(decls:Array<RailsRouteDecl>, splitByScope:Map<String, Bool>, signatureByScope:Map<String, Position>):Void {
		for (decl in decls) {
			if (decl.kind == "deviseFor" && decl.devise != null) {
				var key = decl.devise.mappingScope;
				if (decl.devise.only.length > 0 && decl.devise.skip.length > 0) {
					Context.error('@:railsRoutes Devise mapping scope "${key}" cannot combine only and skip route groups.', decl.pos);
				}
				var split = isDeviseSplitMapping(decl);
				if (splitByScope.exists(key) && (!splitByScope.get(key) || !split)) {
					Context.error('@:railsRoutes duplicate Devise mapping scope "${key}" must use typed only/skip options on every split declaration.',
						decl.pos);
				}
				var signature = deviseMappingSignature(decl);
				if (signatureByScope.exists(signature)) {
					Context.error('@:railsRoutes duplicate Devise mapping scope "${key}" repeats the same only/skip route groups.', decl.pos);
				}
				splitByScope.set(key, split);
				signatureByScope.set(signature, decl.pos);
			}
			if (decl.children.length > 0) {
				validateDeviseMappingsIn(decl.children, splitByScope, signatureByScope);
			}
		}
	}

	static function isDeviseSplitMapping(decl:RailsRouteDecl):Bool {
		return decl.devise != null && (decl.devise.only.length > 0 || decl.devise.skip.length > 0);
	}

	static function deviseMappingSignature(decl:RailsRouteDecl):String {
		if (decl.devise == null) {
			return "";
		}
		return decl.devise.mappingScope + "|only=" + decl.devise.only.join(",") + "|skip=" + decl.devise.skip.join(",");
	}
}
#end
