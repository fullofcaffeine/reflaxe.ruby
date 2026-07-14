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
		validateExtensionLocations(decls, true);
		validateExtensionGroups(decls);
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

	static function validateExtensionLocations(decls:Array<RailsRouteDecl>, topLevel:Bool):Void {
		for (decl in decls) {
			if (decl.extension != null && decl.extension.topLevelOnly && !topLevel) {
				Context.error('@:railsRoutes ${decl.extension.label} must be declared at the top level.', decl.pos);
			}
			if (decl.children.length > 0) {
				validateExtensionLocations(decl.children, false);
			}
		}
	}

	static function validateExtensionGroups(decls:Array<RailsRouteDecl>):Void {
		var splitByGroup = new Map<String, Bool>();
		var signatures = new Map<String, Position>();
		validateExtensionGroupsIn(decls, splitByGroup, signatures);
	}

	static function validateExtensionGroupsIn(decls:Array<RailsRouteDecl>, splitByGroup:Map<String, Bool>, signatures:Map<String, Position>):Void {
		for (decl in decls) {
			if (decl.extension != null && decl.extension.group != "") {
				var extension = decl.extension;
				if (splitByGroup.exists(extension.group) && (!splitByGroup.get(extension.group) || !extension.split)) {
					Context.error('@:railsRoutes duplicate ${extension.label} group "${extension.group}" requires every declaration to opt into splitting.',
						decl.pos);
				}
				var signature = extension.group + "|" + extension.signature;
				if (signatures.exists(signature)) {
					Context.error('@:railsRoutes duplicate ${extension.label} group "${extension.group}" repeats the same declaration.', decl.pos);
				}
				splitByGroup.set(extension.group, extension.split);
				signatures.set(signature, decl.pos);
			}
			if (decl.children.length > 0) {
				validateExtensionGroupsIn(decl.children, splitByGroup, signatures);
			}
		}
	}
}
#end
