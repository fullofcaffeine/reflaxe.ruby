package models;

// Minimal Rails model fixture.
//
// Demonstrates: a RailsHx model with one typed database column.
// Type safety: `@:railsColumn` records compile-time model metadata and exposes
// `AuditLog.f.eventCount` as a typed field ref for query/order helpers.
// IntelliSense: editors should complete `eventCount`, `AuditLog.where(...)`,
// and generated field refs inherited from `Base<AuditLog>`.
// Ruby output: a normal `ApplicationRecord` subclass without runtime schema
// scaffolding.
@:railsModel
class AuditLog extends rails.active_record.Base<AuditLog> {
	@:railsColumn({defaultValue: 0})
	public var eventCount:Int;
}
