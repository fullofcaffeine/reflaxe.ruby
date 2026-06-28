package rails.migration;

typedef ColumnOptions<T> = {
	@:optional var nullable:Bool;
	@:optional var defaultValue:T;
	@:optional var limit:Int;
	@:optional var comment:String;
}

typedef DecimalColumnOptions = {
	@:optional var nullable:Bool;
	@:optional var defaultValue:Float;
	@:optional var precision:Int;
	@:optional var scale:Int;
	@:optional var comment:String;
}

typedef DateColumnOptions = {
	@:optional var nullable:Bool;
	@:optional var defaultValue:String;
	@:optional var comment:String;
}

typedef TemporalColumnOptions = {
	@:optional var nullable:Bool;
	@:optional var defaultValue:String;
	@:optional var precision:Int;
	@:optional var comment:String;
}

typedef JsonColumnOptions = {
	@:optional var nullable:Bool;
	@:optional var defaultValue:String;
	@:optional var comment:String;
}

typedef IndexOptions = {
	@:optional var unique:Bool;
	@:optional var name:String;
	@:optional var ifNotExists:Bool;
	@:optional var comment:String;
}

typedef ReferenceOptions = {
	@:optional var nullable:Bool;
	@:optional var type:PrimaryKeyType;
	@:optional var comment:String;
	@:optional var foreignKey:Bool;
	@:optional var foreignKeyName:String;
	@:optional var foreignKeyToTable:String;
	@:optional var foreignKeyPrimaryKey:String;
	@:optional var foreignKeyOnDelete:ForeignKeyAction;
	@:optional var foreignKeyOnUpdate:ForeignKeyAction;
	@:optional var foreignKeyDeferrable:ForeignKeyDeferrable;
	@:optional var foreignKeyValidate:Bool;
	@:optional var index:Bool;
	@:optional var indexName:String;
	@:optional var indexUnique:Bool;
	@:optional var polymorphic:Bool;
}

typedef CheckConstraintOptions = {
	var name:String;
	@:optional var ifNotExists:Bool;
	@:optional var validate:Bool;
}

typedef UniqueConstraintOptions = {
	var name:String;
	@:optional var deferrable:ForeignKeyDeferrable;
	@:optional var nullsNotDistinct:Bool;
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

typedef TimestampOptions = {
	@:optional var nullable:Bool;
	@:optional var precision:Int;
}

typedef JoinTableOptions = {
	@:optional var tableName:String;
	@:optional var nullable:Bool;
	@:optional var type:PrimaryKeyType;
	@:optional var index:Bool;
	@:optional var ifNotExists:Bool;
	@:optional var ifExists:Bool;
}

typedef SchemaOptions = {
	@:optional var ifNotExists:Bool;
	@:optional var ifExists:Bool;
}

typedef EnumTypeOptions = {
	@:optional var ifExists:Bool;
}

typedef EnumValueOptions = {
	@:optional var ifNotExists:Bool;
	@:optional var before:String;
	@:optional var after:String;
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

enum PrimaryKeyType {
	BigIntPrimaryKey;
	IntegerPrimaryKey;
	UuidPrimaryKey;
	StringPrimaryKey;
}

enum MigrationDefaultValue {
	StringDefault(value:String);
	IntDefault(value:Int);
	FloatDefault(value:Float);
	BoolDefault(value:Bool);
	NullDefault;
}

enum MigrationCommentValue {
	StringComment(value:String);
	NullComment;
}

enum MigrationColumn {
	StringColumn(options:ColumnOptions<String>);
	TextColumn(options:ColumnOptions<String>);
	IntegerColumn(options:ColumnOptions<Int>);
	BooleanColumn(options:ColumnOptions<Bool>);
	FloatColumn(options:ColumnOptions<Float>);
	DecimalColumn(options:DecimalColumnOptions);
	DateColumn(options:DateColumnOptions);
	DateTimeColumn(options:TemporalColumnOptions);
	TimeColumn(options:TemporalColumnOptions);
	BinaryColumn(options:ColumnOptions<String>);
	JsonColumn(options:JsonColumnOptions);
	JsonbColumn(options:JsonColumnOptions);
}

enum CreateTableItem {
	Column(name:String, column:MigrationColumn);
	Reference(name:String, options:ReferenceOptions);
	Index(columns:Array<String>, options:IndexOptions);
}

typedef ChangeTableOptions = {
	@:optional var columns:Array<CreateTableItem>;
	@:optional var bulk:Bool;
	@:optional var timestamps:TimestampOptions;
	@:optional var removeTimestamps:TimestampOptions;
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
		@:optional var id:Bool;
		@:optional var idType:PrimaryKeyType;
		@:optional var primaryKey:String;
		@:optional var primaryKeys:Array<String>;
		@:optional var comment:String;
		@:optional var temporary:Bool;
	});
	ChangeTable(table:String, options:ChangeTableOptions);
	CreateJoinTable(table1:String, table2:String, options:JoinTableOptions);
	DropJoinTable(table1:String, table2:String, options:JoinTableOptions);
	CreateSchema(name:String, options:SchemaOptions);
	DropSchema(name:String, options:SchemaOptions);
	RenameSchema(from:String, to:String);
	CreateEnum(name:String, values:Array<String>);
	DropEnum(name:String, values:Array<String>, options:EnumTypeOptions);
	RenameEnum(from:String, to:String);
	AddEnumValue(name:String, value:String, options:EnumValueOptions);
	RenameEnumValue(name:String, from:String, to:String);
	EnableExtension(name:String);
	DisableExtension(name:String);

	AddColumn(table:String, name:String, column:MigrationColumn);
	AddColumnIfNotExists(table:String, name:String, column:MigrationColumn);
	RemoveColumn(table:String, name:String);
	RemoveColumnIfExists(table:String, name:String);
	RemoveColumnWithType(table:String, name:String, column:MigrationColumn);
	RemoveColumnIfExistsWithType(table:String, name:String, column:MigrationColumn);
	RemoveColumns(table:String, columns:Array<String>);
	RemoveColumnsWithType(table:String, columns:Array<String>, column:MigrationColumn);
	ChangeColumn(table:String, name:String, column:MigrationColumn);
	AddIndex(table:String, column:String, options:IndexOptions);
	AddCompositeIndex(table:String, columns:Array<String>, options:IndexOptions);
	EnableIndex(table:String, name:String);
	DisableIndex(table:String, name:String);
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
	ChangeNullWithDefault(table:String, name:String, nullable:Bool, defaultValue:MigrationDefaultValue);
	ChangeDefault(table:String, name:String, from:MigrationDefaultValue, to:MigrationDefaultValue);
	ChangeColumnComment(table:String, name:String, from:MigrationCommentValue, to:MigrationCommentValue);
	ChangeTableComment(table:String, from:MigrationCommentValue, to:MigrationCommentValue);
	AddTimestamps(table:String, options:TimestampOptions);
	AddTimestampsIfNotExists(table:String, options:TimestampOptions);
	RemoveTimestamps(table:String, options:TimestampOptions);
	AddCheckConstraint(table:String, expression:String, options:CheckConstraintOptions);
	ValidateCheckConstraint(table:String, name:String);
	RemoveCheckConstraint(table:String, name:String);
	RemoveCheckConstraintIfExists(table:String, name:String);
	AddUniqueConstraint(table:String, columns:Array<String>, options:UniqueConstraintOptions);
	RemoveUniqueConstraint(table:String, columns:Array<String>, options:UniqueConstraintOptions);
	DropTable(table:String);
	DropTableIfExists(table:String);
	ExecuteSql(sql:String, rollback:String);
	DataMigration(up:String, down:String);
	Reversible(up:Array<MigrationOperation>, down:Array<MigrationOperation>);
}
