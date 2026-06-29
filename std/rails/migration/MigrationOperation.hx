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

typedef IndexOrder = {
	var column:String;
	var direction:IndexOrderDirection;
}

typedef IndexLength = {
	var column:String;
	var length:Int;
}

typedef IndexOpclass = {
	var column:String;
	var opclass:String;
}

typedef IndexOptions = {
	@:optional var unique:Bool;
	@:optional var name:String;
	@:optional var ifNotExists:Bool;
	@:optional var usingMethod:String;
	@:optional var indexType:String;
	@:optional var indexAlgorithm:IndexAlgorithm;
	@:optional var indexLock:IndexLock;
	@:optional var length:Int;
	@:optional var lengths:Array<IndexLength>;
	@:optional var opclass:String;
	@:optional var opclasses:Array<IndexOpclass>;
	@:optional var orders:Array<IndexOrder>;
	@:optional var includeColumns:Array<String>;
	@:optional var nullsNotDistinct:Bool;
	@:optional var comment:String;
}

typedef MysqlDdlOptions = {
	@:optional var algorithm:MysqlDdlAlgorithm;
	@:optional var lock:IndexLock;
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

typedef ExclusionConstraintOptions = {
	var name:String;
	@:optional var usingMethod:String;
	@:optional var where:String;
	@:optional var deferrable:ForeignKeyDeferrable;
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

enum IndexOrderDirection {
	Asc;
	Desc;
}

enum IndexAlgorithm {
	Inplace;
	Concurrently;
}

enum IndexLock {
	Default;
	None;
	Shared;
	Exclusive;
}

enum MysqlDdlAlgorithm {
	DdlDefault;
	DdlCopy;
	DdlInplace;
	DdlInstant;
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
	@:optional var changeColumns:Array<ChangeTableChangeColumn>;
	@:optional var changeDefaults:Array<ChangeTableChangeDefault>;
	@:optional var changeNulls:Array<ChangeTableChangeNull>;
	@:optional var renameColumns:Array<ChangeTableRenameColumn>;
	@:optional var renameIndexes:Array<ChangeTableRenameIndex>;
	@:optional var checkConstraints:Array<ChangeTableCheckConstraint>;
	@:optional var validateCheckConstraints:Array<String>;
	@:optional var validateConstraints:Array<String>;
	@:optional var foreignKeys:Array<ChangeTableForeignKey>;
	@:optional var uniqueConstraints:Array<ChangeTableUniqueConstraint>;
	@:optional var uniqueConstraintsIfNotExists:Array<ChangeTableUniqueConstraint>;
	@:optional var exclusionConstraints:Array<ChangeTableExclusionConstraint>;
	@:optional var exclusionConstraintsIfNotExists:Array<ChangeTableExclusionConstraint>;
	@:optional var removeCheckConstraints:Array<ChangeTableRemoveCheckConstraint>;
	@:optional var removeColumns:Array<ChangeTableRemoveColumns>;
	@:optional var removeForeignKeys:Array<ChangeTableRemoveForeignKey>;
	@:optional var removeReferences:Array<ChangeTableRemoveReference>;
	@:optional var removeUniqueConstraints:Array<ChangeTableUniqueConstraint>;
	@:optional var removeUniqueConstraintsIfExists:Array<ChangeTableUniqueConstraint>;
	@:optional var removeExclusionConstraints:Array<ChangeTableExclusionConstraint>;
	@:optional var removeExclusionConstraintsIfExists:Array<ChangeTableExclusionConstraint>;
	@:optional var removeIndexes:Array<ChangeTableRemoveIndex>;
	@:optional var bulk:Bool;
	@:optional var timestamps:TimestampOptions;
	@:optional var removeTimestamps:TimestampOptions;
}

typedef ChangeTableChangeColumn = {
	var name:String;
	var column:MigrationColumn;
}

typedef ChangeTableChangeDefault = {
	var name:String;
	var from:MigrationDefaultValue;
	var to:MigrationDefaultValue;
}

typedef ChangeTableChangeNull = {
	var name:String;
	var nullable:Bool;
	@:optional var defaultValue:MigrationDefaultValue;
}

typedef ChangeTableRenameColumn = {
	var from:String;
	var to:String;
}

typedef ChangeTableRenameIndex = {
	var from:String;
	var to:String;
}

typedef ChangeTableCheckConstraint = {
	var expression:String;
	var options:CheckConstraintOptions;
}

typedef ChangeTableForeignKey = {
	var toTable:String;
	var options:ForeignKeyOptions;
}

typedef ChangeTableUniqueConstraint = {
	var columns:Array<String>;
	var options:UniqueConstraintOptions;
}

typedef ChangeTableExclusionConstraint = {
	var expression:String;
	var options:ExclusionConstraintOptions;
}

typedef ChangeTableRemoveCheckConstraint = {
	var name:String;
	@:optional var ifExists:Bool;
}

typedef ChangeTableRemoveColumns = {
	var columns:Array<String>;
	var column:MigrationColumn;
}

typedef ChangeTableRemoveForeignKey = {
	@:optional var toTable:String;
	@:optional var column:String;
	@:optional var name:String;
}

typedef ChangeTableRemoveReference = {
	var name:String;
	var options:ReferenceOptions;
}

typedef ChangeTableRemoveIndex = {
	var columns:Array<String>;
	@:optional var name:String;
	@:optional var ifExists:Bool;
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
	AddColumnWithDdl(table:String, name:String, column:MigrationColumn, options:MysqlDdlOptions);
	AddColumnIfNotExists(table:String, name:String, column:MigrationColumn);
	AddColumnIfNotExistsWithDdl(table:String, name:String, column:MigrationColumn, options:MysqlDdlOptions);
	RemoveColumn(table:String, name:String);
	RemoveColumnIfExists(table:String, name:String);
	RemoveColumnWithType(table:String, name:String, column:MigrationColumn);
	RemoveColumnWithDdl(table:String, name:String, column:MigrationColumn, options:MysqlDdlOptions);
	RemoveColumnIfExistsWithType(table:String, name:String, column:MigrationColumn);
	RemoveColumnIfExistsWithDdl(table:String, name:String, column:MigrationColumn, options:MysqlDdlOptions);
	RemoveColumns(table:String, columns:Array<String>);
	RemoveColumnsWithType(table:String, columns:Array<String>, column:MigrationColumn);
	ChangeColumn(table:String, name:String, column:MigrationColumn);
	ChangeColumnWithDdl(table:String, name:String, column:MigrationColumn, options:MysqlDdlOptions);
	AddIndex(table:String, column:String, options:IndexOptions);
	AddCompositeIndex(table:String, columns:Array<String>, options:IndexOptions);
	EnableIndex(table:String, name:String);
	DisableIndex(table:String, name:String);
	RemoveIndex(table:String, column:String);
	RemoveIndexWithDdl(table:String, column:String, options:MysqlDdlOptions);
	RemoveIndexIfExists(table:String, column:String);
	RemoveIndexIfExistsWithDdl(table:String, column:String, options:MysqlDdlOptions);
	RemoveIndexByName(table:String, name:String);
	RemoveIndexByNameWithDdl(table:String, name:String, options:MysqlDdlOptions);
	RemoveIndexByNameIfExists(table:String, name:String);
	RemoveIndexByNameIfExistsWithDdl(table:String, name:String, options:MysqlDdlOptions);
	RemoveCompositeIndex(table:String, columns:Array<String>);
	RemoveCompositeIndexWithDdl(table:String, columns:Array<String>, options:MysqlDdlOptions);
	RemoveCompositeIndexIfExists(table:String, columns:Array<String>);
	RemoveCompositeIndexIfExistsWithDdl(table:String, columns:Array<String>, options:MysqlDdlOptions);
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
	RenameColumnWithDdl(table:String, from:String, to:String, options:MysqlDdlOptions);
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
	ValidateConstraint(table:String, name:String);
	RemoveConstraint(table:String, name:String);
	RemoveCheckConstraint(table:String, name:String);
	RemoveCheckConstraintIfExists(table:String, name:String);
	AddUniqueConstraint(table:String, columns:Array<String>, options:UniqueConstraintOptions);
	AddUniqueConstraintIfNotExists(table:String, columns:Array<String>, options:UniqueConstraintOptions);
	AddUniqueConstraintUsingIndex(table:String, indexName:String, options:UniqueConstraintOptions);
	RemoveUniqueConstraint(table:String, columns:Array<String>, options:UniqueConstraintOptions);
	RemoveUniqueConstraintIfExists(table:String, columns:Array<String>, options:UniqueConstraintOptions);
	AddExclusionConstraint(table:String, expression:String, options:ExclusionConstraintOptions);
	AddExclusionConstraintIfNotExists(table:String, expression:String, options:ExclusionConstraintOptions);
	RemoveExclusionConstraint(table:String, expression:String, options:ExclusionConstraintOptions);
	RemoveExclusionConstraintIfExists(table:String, expression:String, options:ExclusionConstraintOptions);
	DropTable(table:String);
	DropTableIfExists(table:String);
	ExecuteSql(sql:String, rollback:String);
	DataMigration(up:String, down:String);
	Reversible(up:Array<MigrationOperation>, down:Array<MigrationOperation>);
}
