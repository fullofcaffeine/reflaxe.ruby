package rails.migration;

typedef ColumnOptions<T> = {
	@:optional var nullable:Bool;
	@:optional var defaultValue:T;
}

typedef IndexOptions = {
	@:optional var unique:Bool;
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
	AddIndex(table:String, column:String, options:IndexOptions);
	RemoveIndex(table:String, column:String);
	DropTable(table:String);
}
