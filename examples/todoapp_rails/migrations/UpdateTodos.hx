package migrations;

import rails.migration.Migration;
import rails.migration.MigrationOperation;

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
