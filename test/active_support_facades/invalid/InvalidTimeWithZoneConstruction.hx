class InvalidTimeWithZoneConstruction {
	static function main():Void {
		var value = new rails.active_support.TimeWithZone();
		Sys.println(value);
	}
}
