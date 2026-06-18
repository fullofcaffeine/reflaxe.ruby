package migrations;

import rails.migration.Migration;
import rails.migration.MigrationOperation;
import rails.migration.MigrationOperation.CreateTableItem;

// Chat messages migration snapshot.
//
// Demonstrates: adding a production-style feature table as an immutable Haxe
// migration operation snapshot.
// Type safety: `CreateTable`, `Column`, `Reference`, and `Index` keep the table
// shape explicit and checked without depending on mutable model metadata.
// IntelliSense: editors should complete migration operation constructors and
// typed option fields.
// Ruby/Rails output: a timestamped ActiveRecord migration for `chat_messages`.
@:railsMigration({
	timestamp: "20260101000003",
	className: "CreateChatMessages",
	version: "7.1",
	models: []
})
class CreateChatMessages extends Migration {
	public static final operations:Array<MigrationOperation> = [
		CreateTable("chat_messages", {
			columns: [
				Column("body", TextColumn({nullable: false})),
				Reference("user", {nullable: false, foreignKey: true}),
				Index(["user_id", "id"], {})
			],
			timestamps: true
		})
	];
}
