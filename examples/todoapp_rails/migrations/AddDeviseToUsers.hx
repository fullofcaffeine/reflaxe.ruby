package migrations;

import rails.migration.Migration;
import rails.migration.MigrationOperation;

// Devise storage migration.
//
// Demonstrates: a later Haxe-authored migration snapshot for a gem companion
// layer. The app keeps Devise runtime semantics, while Haxe owns the typed
// migration operation that adds Devise's required encrypted password column.
// Type safety: `AddColumn` and `StringColumn` constrain the generated
// ActiveRecord operation without depending on mutable `models.User` metadata.
// IntelliSense: editors should complete migration operation constructors and
// column option fields.
// Ruby/Rails output: `add_column :users, :encrypted_password, :string, ...` in a
// normal timestamped ActiveRecord migration that Rails executes with db:migrate.
@:railsMigration({
	timestamp: "20260101000004",
	className: "AddDeviseToUsers",
	version: "7.1",
	models: []
})
class AddDeviseToUsers extends Migration {
	public static final operations:Array<MigrationOperation> = [
		AddColumn("users", "encrypted_password", StringColumn({nullable: false, defaultValue: ""}))
	];
}
