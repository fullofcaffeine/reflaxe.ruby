package migrations;

import rails.migration.Migration;
import rails.migration.MigrationOperation;

// Typed migration operation fixture.
//
// Demonstrates: explicit reversible operations, column changes, foreign keys,
// added columns, named/idempotent indexes, composite indexes, idempotent check
// constraints, and data migrations authored as Haxe enum values.
// Type safety: `MigrationOperation` constructors constrain operation shapes and
// option objects; `knownModels` lets the compiler validate table/column/index
// references without re-emitting create-table migrations; irreversible
// operations require an explicit reversible shape.
// IntelliSense: editors should complete operations such as `ChangeColumn`,
// `AddForeignKey`, `IntegerColumn`, and enum options such as `Cascade`.
// Ruby/Rails output: standard ActiveRecord migration statements.
@:railsMigration({
	timestamp: "20260101000001",
	className: "UpdateTodos",
	version: "7.1",
	models: [],
	knownModels: ["models.Todo", "models.User"]
})
class UpdateTodos extends Migration {
	public static final operations:Array<MigrationOperation> = [
		Reversible([
			ChangeColumn("todos", "title", StringColumn({nullable: false})),
			AddForeignKey("todos", "users", {column: "user_id", name: "fk_todos_users", onDelete: Cascade})
		], [
			RemoveForeignKeyByName("todos", "fk_todos_users"),
			ChangeColumn("todos", "title", StringColumn({nullable: true}))
		]),
		AddColumn("todos", "priority", IntegerColumn({nullable: false, defaultValue: 0})),
		AddIndex("todos", "priority", {unique: false, name: "index_todos_on_priority"}),
		Reversible([
			AddCheckConstraint("todos", "priority >= 0", {name: "chk_todos_priority_non_negative", ifNotExists: true})
		], [
			RemoveCheckConstraintIfExists("todos", "chk_todos_priority_non_negative")
		]),
		Reversible([
			AddCompositeIndex("todos", ["user_id", "priority"], {name: "index_todos_on_user_id_and_priority"})
		], [
			RemoveIndexByNameIfExists("todos", "index_todos_on_user_id_and_priority")
		]),
		DataMigration("UPDATE todos SET priority = 0 WHERE priority IS NULL", "UPDATE todos SET priority = NULL WHERE priority = 0")
	];
}
