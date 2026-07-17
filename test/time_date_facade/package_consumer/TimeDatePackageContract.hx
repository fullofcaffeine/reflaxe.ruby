import ruby.Date as RubyDate;
import ruby.Time as RubyTime;

/** Proves released packages expose both bounded native time/date contracts. **/
class TimeDatePackageContract {
	public static function verify():Void {
		var instant = RubyTime.utc(2024, 2, 29).addSeconds(60);
		var date = new RubyDate(2024, 2, 29).nextDay();
		var portable = new Date(2024, 1, 29, 0, 0, 0);
		if (instant.minute() != 1 || date.toIso8601() != "2024-03-01" || portable.getMonth() != 1) {
			throw "packaged Time/Date contract mismatch";
		}
	}
}
