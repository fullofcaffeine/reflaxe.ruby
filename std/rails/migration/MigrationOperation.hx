package rails.migration;

typedef ColumnOptions<T> = {
	@:optional var nullable:Bool;
	@:optional var defaultValue:T;
}

typedef IndexOptions = {
	@:optional var unique:Bool;
}

typedef ForeignKeyOptions = {
	@:optional var column:String;
	@:optional var primaryKey:String;
	@:optional var onDelete:ForeignKeyAction;
	@:optional var onUpdate:ForeignKeyAction;
}

enum ForeignKeyAction {
	Cascade;
	Nullify;
	Restrict;
}

enum MigrationColumn {
	StringColumn(options:ColumnOptions<String>);
	TextColumn(options:ColumnOptions<String>);
	IntegerColumn(options:ColumnOptions<Int>);
	BooleanColumn(options:ColumnOptions<Bool>);
	FloatColumn(options:ColumnOptions<Float>);
}

enum MigrationOperation {
	AddColumn(table:String, name:String, column:MigrationColumn);
	RemoveColumn(table:String, name:String);
	ChangeColumn(table:String, name:String, column:MigrationColumn);
	AddIndex(table:String, column:String, options:IndexOptions);
	RemoveIndex(table:String, column:String);
	AddForeignKey(fromTable:String, toTable:String, options:ForeignKeyOptions);
	RemoveForeignKey(fromTable:String, toTable:String);
	DropTable(table:String);
	Reversible(up:Array<MigrationOperation>, down:Array<MigrationOperation>);
}
