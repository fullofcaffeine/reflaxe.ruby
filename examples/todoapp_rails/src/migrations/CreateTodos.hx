package migrations;

import rails.migration.Migration;
import rails.migration.MigrationOperation;
import rails.migration.MigrationOperation.CreateTableItem;

// Initial typed Rails migration.
//
// Demonstrates: production-preferred operation snapshots. This mirrors what
// `bin/rails generate hxruby:migration CreateTodos ...` writes: the migration
// records historical table operations explicitly instead of depending on the
// current model metadata forever.
// Type safety: `MigrationOperation` and `CreateTableItem` constrain tables,
// columns, references, indexes, null/default options, and Rails migration
// version metadata before Ruby/Rails runs.
// IntelliSense: editors should complete `CreateTable`, `Column`, `Reference`,
// `Index`, column constructors, and typed option object fields.
// Ruby/Rails output: timestamped `db/migrate/**` ActiveRecord files with normal
// `create_table`, `t.references`, `t.index`, and `t.timestamps` calls.
@:railsMigration({
	timestamp: "20260101000000",
	className: "CreateTodos",
	version: "7.1",
	models: []
})
class CreateTodos extends Migration {
	public static final operations:Array<MigrationOperation> = [
		CreateTable("users", {
			columns: [
				Column("name", StringColumn({nullable: false})),
				Index(["name"], {})
			],
			timestamps: true
		}),
		CreateTable("todos", {
			columns: [
				Column("title", StringColumn({nullable: false})),
				Index(["title"], {}),
				Column("notes", TextColumn({nullable: false, defaultValue: ""})),
				Column("is_completed", BooleanColumn({nullable: false, defaultValue: false})),
				Reference("user", {nullable: false, foreignKey: true})
			],
			timestamps: true
		})
	];
}
