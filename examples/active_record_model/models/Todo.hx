package models;

@:railsModel("todos")
@:railsTimestamps
class Todo extends rails.active_record.Base<Todo> {
	@:railsColumn({primaryKey: true, dbType: "bigint"})
	public var id:Int;

	@:railsColumn({index: true})
	public var title:String;

	@:railsColumn({defaultValue: false})
	public var completed:Bool;

	@:railsColumn({nullable: true, dbType: "text"})
	public var notes:Null<String>;

	@:railsColumn({unique: true})
	public var externalId:String;
}
