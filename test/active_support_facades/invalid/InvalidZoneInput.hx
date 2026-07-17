class InvalidZoneInput {
	static function main():Void {
		var zone = rails.active_support.RailsTime.findZoneRequired(123);
		Sys.println(zone);
	}
}
