package rails.migration;

/**
	Marker base for Haxe-authored Rails migrations.

	`@:railsMigration(...)` classes are compile-time inputs. The Ruby compiler
	emits standard `db/migrate/*.rb` ActiveRecord migration artifacts from them.

	Options:
	- `models`: typed `@:railsModel` classes to create in this migration.
	- `knownModels`: typed `@:railsModel` classes used only for validation of
	  table and existing-column references. They are not emitted as `create_table`,
	  and they do not make historical `AddColumn` snapshots invalid just because
	  today's model metadata now contains that column.
	- `externalTables`: Rails-owned table names that should remain unchecked when
	  Haxe does not own their schema, such as legacy tables or engine tables.
**/
class Migration {}
