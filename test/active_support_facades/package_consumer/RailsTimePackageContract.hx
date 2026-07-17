import rails.active_support.RailsTime;

/** Proves an installed Haxelib exposes the modern Rails temporal contracts. **/
class RailsTimePackageContract {
	static function main():Void {
		var zone = RailsTime.findZoneRequired("UTC");
		var instant = zone.parseIso8601("2026-07-17T12:30:00Z");
		Sys.println(instant.toUtc().year());
	}
}
