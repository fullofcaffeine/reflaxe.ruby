package reflaxe.ruby.rails;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Type.TypedExpr;

/**
	Owns fail-closed rules that prevent Rails migration rollback data loss.

	RubyCompiler still parses and emits the existing MigrationOperation surface.
	This service owns only cross-operation safety decisions that must remain
	consistent as migration lowering moves out of the compiler root. It does not
	introduce another migration representation or emit Ruby.
**/
class RailsMigrationSafety {
	/** Returns true when a name-only removal cannot describe its own rollback. **/
	public static function requiresExplicitReversible(operation:String, argumentCount:Int):Bool {
		return switch (operation) {
			case "RemoveIndexByName" | "RemoveIndexByNameIfExists" | "RemoveForeignKeyByName" | "RemoveForeignKeyByNameIfExists" if (argumentCount == 2):
				true;
			case "RemoveIndexByNameWithDdl" | "RemoveIndexByNameIfExistsWithDdl" if (argumentCount == 3):
				true;
			case _:
				false;
		}
	}

	/** Rejects an operation when its rollback shape is not explicit. **/
	public static function requireExplicit(operation:String, inExplicitReversible:Bool, expr:TypedExpr):Void {
		if (!inExplicitReversible) {
			Context.error('@:railsMigration ${operation} must be wrapped in Reversible(up, down) so RailsHx has an explicit rollback shape.', expr.pos);
		}
	}

	/**
		Rejects ChangeTable blocks that would silently make schema changes up-only.

		Rails validation commands have no automatic down action. Mixing one with
		reversible schema members would wrap the complete block as up-only and lose
		the schema rollback, so callers must split the operations.
	**/
	public static function rejectMixedChangeTable(validationCount:Int, memberCount:Int, expr:TypedExpr):Void {
		if (validationCount > 0 && memberCount > validationCount) {
			Context.error("@:railsMigration ChangeTable cannot mix validation and schema-change members. Put validation members in a separate ChangeTable operation so reversible schema changes are not made up-only.",
				expr.pos);
		}
	}
}
#end
