package rails.migration;

/**
	Marker base for Haxe-authored Rails migrations.

	`@:railsMigration(...)` classes are compile-time inputs. The Ruby compiler
	emits standard `db/migrate/*.rb` ActiveRecord migration artifacts from them.
**/
class Migration {}
