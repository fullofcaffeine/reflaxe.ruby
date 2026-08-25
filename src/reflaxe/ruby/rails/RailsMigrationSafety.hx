package reflaxe.ruby.rails;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Type;
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

	/** Reads the removal-only guard without letting it leak into restoration data. **/
	public static function removalIfExists(expr:TypedExpr, label:String):Bool {
		return switch (unwrap(expr).expr) {
			case TObjectDecl(fields):
				var ifExists = false;
				for (field in fields) {
					switch (field.name) {
						case "ifExists":
							switch (unwrap(field.expr).expr) {
								case TConst(TBool(value)): ifExists = value;
								case _: Context.error('@:railsMigration ${label} ifExists must be a Bool literal.', field.expr.pos);
							}
						case _: Context.error('@:railsMigration unknown ${label} option ${field.name}.', field.expr.pos);
					}
				}
				ifExists;
			case _:
				Context.error('@:railsMigration ${label} must be an object literal.', expr.pos);
				false;
		}
	}

	static function unwrap(expr:TypedExpr):TypedExpr {
		return switch (expr.expr) {
			case TCast(inner, _) | TMeta(_, inner) | TParenthesis(inner): unwrap(inner);
			case _: expr;
		}
	}

	/** Ensures an explicit rollback failure cannot run forward or hide sibling work. **/
	public static function requireIrreversibleDown(inDown:Bool, operationCount:Int, expr:TypedExpr):Void {
		if (!inDown || operationCount != 1) {
			Context.error("@:railsMigration Irreversible is legal only as the sole operation in a Reversible down branch.", expr.pos);
		}
	}

	/** Validates and returns the reason used by Rails' native rollback failure. **/
	public static function irreversibleReason(reasonExpr:TypedExpr, inDown:Bool, operationCount:Int, callExpr:TypedExpr):String {
		requireIrreversibleDown(inDown, operationCount, callExpr);
		return switch (unwrap(reasonExpr).expr) {
			case TConst(TString(value)) if (value != ""): value;
			case _:
				Context.error("@:railsMigration Irreversible reason must be a non-empty String literal.", reasonExpr.pos);
				"";
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
