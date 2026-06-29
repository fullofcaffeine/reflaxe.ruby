package migrations;

import rails.migration.Migration;
import rails.migration.MigrationOperation;

// User profile migration.
//
// Demonstrates: production-safe additive migration snapshots for model fields
// added after the initial app migration.
// Type safety: the operation enum constrains table/column/index shapes while
// the snapshot remains independent from current `models.User` metadata. That
// independence matters for additive migrations: the current model already knows
// about `email`/`role`, but this historical migration is what added them.
// IntelliSense: editors should complete `AddColumn`, `AddIndex`, and typed
// column/index option fields.
// Ruby/Rails output: a timestamped ActiveRecord migration adding email/role
// profile columns and indexes.
@:railsMigration({
	timestamp: "20260101000002",
	className: "UpdateUsers",
	version: "7.1",
	models: []
})
class UpdateUsers extends Migration {
	public static final operations:Array<MigrationOperation> = [
		AddColumn("users", "email", StringColumn({nullable: false, defaultValue: "owner@example.test"})),
		AddColumn("users", "role", StringColumn({nullable: false, defaultValue: "member"})),
		AddIndex("users", "email", {unique: true}),
		AddIndex("users", "role", {ifNotExists: true})
	];
}
