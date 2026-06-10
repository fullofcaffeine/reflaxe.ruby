package models;

@:railsModel("todos")
class Todo extends rails.active_record.Base<Todo> {
	@:railsColumn public var title:String;
	@:railsColumn public var completed:Bool;
}
