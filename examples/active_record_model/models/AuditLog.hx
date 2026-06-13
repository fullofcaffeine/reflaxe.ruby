package models;

// Minimal Rails model fixture.
//
// Demonstrates: a RailsHx model with one typed database column.
// Type safety: `@:railsColumn` records schema metadata and exposes
// `AuditLog.f.eventCount` as a typed field ref for query/order helpers.
// IntelliSense: editors should complete `eventCount`, `AuditLog.where(...)`,
// and generated field refs inherited from `Base<AuditLog>`.
// Ruby output: an `ApplicationRecord` subclass with Rails schema metadata.
@:railsModel
class AuditLog extends rails.active_record.Base<AuditLog> {
	@:railsColumn({defaultValue: 0})
	public var eventCount:Int;
}
