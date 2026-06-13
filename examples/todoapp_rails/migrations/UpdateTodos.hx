package migrations;

import rails.migration.Migration;
import rails.migration.MigrationOperation;

// Typed migration operation fixture.
//
// Demonstrates: explicit reversible operations, column changes, foreign keys,
// added columns, and indexes authored as Haxe enum values.
// Type safety: `MigrationOperation` constructors constrain operation shapes and
// option objects; irreversible operations require an explicit reversible shape.
// IntelliSense: editors should complete operations such as `ChangeColumn`,
// `AddForeignKey`, `IntegerColumn`, and enum options such as `Cascade`.
// Ruby/Rails output: standard ActiveRecord migration statements.
@:railsMigration({
	timestamp: "20260101000001",
	className: "UpdateTodos",
	models: []
})
class UpdateTodos extends Migration {
	public static final operations:Array<MigrationOperation> = [
		Reversible([
			ChangeColumn("todos", "title", StringColumn({nullable: false})),
			AddForeignKey("todos", "users", {column: "user_id", onDelete: Cascade})
		], [
			RemoveForeignKey("todos", "users"),
			ChangeColumn("todos", "title", StringColumn({nullable: true}))
		]),
		AddColumn("todos", "priority", IntegerColumn({nullable: false, defaultValue: 0})),
		AddIndex("todos", "priority", {unique: false})
	];
}
