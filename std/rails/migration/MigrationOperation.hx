package rails.migration;

typedef ColumnOptions<T> = {
	@:optional var nullable:Bool;
	@:optional var defaultValue:T;
	@:optional var limit:Int;
}

typedef DecimalColumnOptions = {
	@:optional var nullable:Bool;
	@:optional var defaultValue:Float;
	@:optional var precision:Int;
	@:optional var scale:Int;
}

typedef IndexOptions = {
	@:optional var unique:Bool;
	@:optional var name:String;
	@:optional var ifNotExists:Bool;
}

typedef ReferenceOptions = {
	@:optional var nullable:Bool;
	@:optional var foreignKey:Bool;
	@:optional var foreignKeyName:String;
	@:optional var index:Bool;
	@:optional var polymorphic:Bool;
}

typedef CheckConstraintOptions = {
	var name:String;
	@:optional var ifNotExists:Bool;
	@:optional var validate:Bool;
}

typedef ForeignKeyOptions = {
	@:optional var column:String;
	@:optional var name:String;
	@:optional var primaryKey:String;
	@:optional var onDelete:ForeignKeyAction;
	@:optional var onUpdate:ForeignKeyAction;
	@:optional var ifNotExists:Bool;
	@:optional var validate:Bool;
	@:optional var deferrable:ForeignKeyDeferrable;
}

enum ForeignKeyAction {
	Cascade;
	Nullify;
	Restrict;
}

enum ForeignKeyDeferrable {
	Immediate;
	Deferred;
}

enum MigrationColumn {
	StringColumn(options:ColumnOptions<String>);
	TextColumn(options:ColumnOptions<String>);
	IntegerColumn(options:ColumnOptions<Int>);
	BooleanColumn(options:ColumnOptions<Bool>);
	FloatColumn(options:ColumnOptions<Float>);
	DecimalColumn(options:DecimalColumnOptions);
}

enum CreateTableItem {
	Column(name:String, column:MigrationColumn);
	Reference(name:String, options:ReferenceOptions);
	Index(columns:Array<String>, options:IndexOptions);
}

enum MigrationOperation {
	/**
		Typed Rails migration operations lower to normal ActiveRecord statements.

		When `@:railsMigration({knownModels: [...]})` is present, the compiler
		validates table, column, index, and foreign-key column references against
		the referenced `@:railsModel` metadata. `knownModels` describes today's
		typed schema, so historical `AddColumn` operations may still add a column
		that now exists on the model; duplicate additions inside the same migration
		snapshot are still rejected. Use `externalTables` for deliberate interop
		with Rails-owned tables that Haxe does not own.
	**/
	CreateTable(table:String, options:{
		var columns:Array<CreateTableItem>;
		@:optional var timestamps:Bool;
		@:optional var ifNotExists:Bool;
	});

	AddColumn(table:String, name:String, column:MigrationColumn);
	AddColumnIfNotExists(table:String, name:String, column:MigrationColumn);
	RemoveColumn(table:String, name:String);
	RemoveColumnIfExists(table:String, name:String);
	ChangeColumn(table:String, name:String, column:MigrationColumn);
	AddIndex(table:String, column:String, options:IndexOptions);
	AddCompositeIndex(table:String, columns:Array<String>, options:IndexOptions);
	RemoveIndex(table:String, column:String);
	RemoveIndexIfExists(table:String, column:String);
	RemoveIndexByName(table:String, name:String);
	RemoveIndexByNameIfExists(table:String, name:String);
	RemoveCompositeIndex(table:String, columns:Array<String>);
	RemoveCompositeIndexIfExists(table:String, columns:Array<String>);
	RenameIndex(table:String, from:String, to:String);
	AddReference(table:String, name:String, options:ReferenceOptions);
	AddReferenceIfNotExists(table:String, name:String, options:ReferenceOptions);
	RemoveReference(table:String, name:String, options:ReferenceOptions);
	RemoveReferenceIfExists(table:String, name:String, options:ReferenceOptions);
	AddForeignKey(fromTable:String, toTable:String, options:ForeignKeyOptions);
	ValidateForeignKey(fromTable:String, toTable:String);
	ValidateForeignKeyByName(fromTable:String, name:String);
	RemoveForeignKey(fromTable:String, toTable:String);
	RemoveForeignKeyIfExists(fromTable:String, toTable:String);
	RemoveForeignKeyByName(fromTable:String, name:String);
	RemoveForeignKeyByNameIfExists(fromTable:String, name:String);
	RenameColumn(table:String, from:String, to:String);
	RenameTable(from:String, to:String);
	ChangeNull(table:String, name:String, nullable:Bool);
	AddCheckConstraint(table:String, expression:String, options:CheckConstraintOptions);
	ValidateCheckConstraint(table:String, name:String);
	RemoveCheckConstraint(table:String, name:String);
	RemoveCheckConstraintIfExists(table:String, name:String);
	DropTable(table:String);
	DropTableIfExists(table:String);
	ExecuteSql(sql:String, rollback:String);
	DataMigration(up:String, down:String);
	Reversible(up:Array<MigrationOperation>, down:Array<MigrationOperation>);
}
