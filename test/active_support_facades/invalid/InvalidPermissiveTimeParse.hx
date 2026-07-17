class InvalidPermissiveTimeParse {
	static function main():Void {
		var zone = rails.active_support.RailsTime.findZoneRequired("UTC");
		var value = zone.parse("tomorrow noon");
		Sys.println(value);
	}
}
