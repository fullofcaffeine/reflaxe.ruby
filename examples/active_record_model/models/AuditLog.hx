package models;

@:railsModel
class AuditLog extends rails.active_record.Base<AuditLog> {
	@:railsColumn({defaultValue: 0})
	public var eventCount:Int;
}
