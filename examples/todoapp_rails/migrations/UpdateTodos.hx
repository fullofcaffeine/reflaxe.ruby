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
		AddColumn("todos", "priority", IntegerColumn({nullable: false, defaultValue: 0})),
		AddIndex("todos", "priority", {unique: false}),
		RemoveIndex("todos", "priority"),
		RemoveColumn("todos", "priority")
	];
}
