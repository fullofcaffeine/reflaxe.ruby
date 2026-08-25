package reflaxe.ruby.rails;

/** A table dependency used to validate generated migration order. */
typedef RailsMigrationForeignKeyRef = {
	fromTable:String,
	toTable:String
}

/** Ruby lines and ordering facts for one already-validated migration operation. */
typedef RailsMigrationOperationInfo = {
	lines:Array<String>,
	foreignKeys:Array<RailsMigrationForeignKeyRef>
}

/**
	Renders Rails migration syntax after RubyCompiler has validated typed input.

	This module does not inspect Haxe expressions or decide migration semantics. It
	owns the structural indentation of explicit Rails `reversible` blocks so the
	compiler root can remain an orchestration entrypoint.
**/
class RailsMigrationSyntax {
	/** Renders an index removal whose down branch recreates the complete definition. */
	public static function exactIndexRemoval(table:String, columns:String, restoration:Array<String>, ifExists:Bool):RailsMigrationOperationInfo {
		return exactRemoval("remove_index :"
			+ table
			+ optionSuffix(["column: " + columns].concat(restoration)),
			"add_index :"
			+ table
			+ ", "
			+ columns
			+ optionSuffix(restoration), ifExists);
	}

	/** Renders a foreign-key removal whose down branch excludes removal-only policy. */
	public static function exactForeignKeyRemoval(fromTable:String, toTable:String, restoration:Array<String>, ifExists:Bool):RailsMigrationOperationInfo {
		var target = ":" + fromTable + ", :" + toTable + optionSuffix(restoration);
		return exactRemoval("remove_foreign_key " + target, "add_foreign_key " + target, ifExists);
	}

	/** Keeps a removal guard out of the explicit restoration statement. */
	static function exactRemoval(remove:String, restore:String, ifExists:Bool):RailsMigrationOperationInfo {
		var guardedRemove = remove + (ifExists ? ", if_exists: true" : "");
		return reversible([{lines: [guardedRemove], foreignKeys: []}], [{lines: [restore], foreignKeys: []}]);
	}

	/** Renders validated operation lists as one Rails reversible block. */
	public static function reversible(up:Array<RailsMigrationOperationInfo>, down:Array<RailsMigrationOperationInfo>):RailsMigrationOperationInfo {
		var lines = ["reversible do |dir|", "  dir.up do"];
		var foreignKeys:Array<RailsMigrationForeignKeyRef> = [];
		for (operation in up) {
			foreignKeys = foreignKeys.concat(operation.foreignKeys);
			for (line in operation.lines)
				lines.push("    " + line);
		}
		lines.push("  end");
		lines.push("  dir.down do");
		for (operation in down) {
			for (line in operation.lines)
				lines.push("    " + line);
		}
		lines.push("  end");
		lines.push("end");
		return {lines: lines, foreignKeys: foreignKeys};
	}

	static function optionSuffix(options:Array<String>):String {
		return options.length == 0 ? "" : ", " + options.join(", ");
	}
}
