import ruby.Date as RubyDate;
import ruby.Time as RubyTime;
import ruby.TimeParsing;

/**
	Executable contract for the native Ruby-semantic Time and Date facades.

	The fixed UTC values make epoch, calendar, offset, formatting, parsing, and
	arithmetic behavior deterministic. Generated Ruby should call core `Time` and
	require-backed `Date` directly without confusing either type with Haxe Date.
**/
class Main {
	static function main():Void {
		var utc = RubyTime.utc(2024, 2, 29, 12, 34, 56);
		Sys.println(utc.year());
		Sys.println(utc.month());
		Sys.println(utc.day());
		Sys.println(utc.hour());
		Sys.println(utc.minute());
		Sys.println(utc.second());
		Sys.println(utc.weekday());
		Sys.println(utc.yearDay());
		Sys.println(utc.isUtc());
		Sys.println(utc.isDaylightSavingTime());
		Sys.println(utc.utcOffsetSeconds());
		var zone:Null<String> = utc.zone();
		Sys.println(zone);
		Sys.println(utc.strftime("%Y-%m-%d %H:%M:%S %z"));
		Sys.println(utc.toEpochSecond() == 1709210096);
		Sys.println(utc.toEpochSeconds() == 1709210096.0);

		var later = utc.addSeconds(90.5);
		Sys.println(later.strftime("%Y-%m-%d %H:%M:%S.%L"));
		Sys.println(later.secondsSince(utc));
		Sys.println(later.subtractSeconds(90.5).strftime("%H:%M:%S"));
		Sys.println(utc.toOffset(7200).strftime("%H:%M:%S %z"));
		Sys.println(utc.toLocal().toUtc().strftime("%H:%M:%S %z"));
		Sys.println(RubyTime.at(1709210096.0).toUtc().strftime("%Y-%m-%d %H:%M:%S"));
		Sys.println(RubyTime.local(2024, 2, 29, 12, 34, 56).isUtc());
		Sys.println(RubyTime.now().year() > 0);
		Sys.println(TimeParsing.parseIso8601("2026-07-17T12:30:00-06:00").toUtc().strftime("%Y-%m-%d %H:%M:%S %z"));
		Sys.println(TimeParsing.parseWithFormat("2026/07/17 12:30 -0600", "%Y/%m/%d %H:%M %z").toUtc().strftime("%Y-%m-%d %H:%M:%S %z"));

		var leap = new RubyDate(2024, 2, 29);
		Sys.println(leap.toIso8601());
		Sys.println(leap.year());
		Sys.println(leap.month());
		Sys.println(leap.day());
		Sys.println(leap.weekday());
		Sys.println(leap.yearDay());
		Sys.println(leap.isoWeekYear());
		Sys.println(leap.isoWeek());
		Sys.println(leap.isoWeekday());
		Sys.println(leap.isLeapYear());
		Sys.println(leap.nextDay().toString());
		Sys.println(leap.nextDay(2).toString());
		Sys.println(leap.previousDay().toString());
		Sys.println(leap.nextMonth().toString());
		Sys.println(leap.previousMonth().toString());
		Sys.println(leap.nextYear().toString());
		Sys.println(leap.previousYear().toString());
		Sys.println(leap.strftime("%A, %d %B %Y"));
		Sys.println(RubyDate.parseIso8601("2025-12-31").toString());
		Sys.println(RubyDate.parseWithFormat("31/12/2025", "%d/%m/%Y").toIso8601());
		Sys.println(RubyDate.today().year() > 0);

		// Portable Haxe Date remains zero-based and lowers to a collision-safe
		// HxDate constant while the native Ruby Date facade is present.
		var portable = new Date(2024, 1, 29, 0, 0, 0);
		Sys.println(portable.getMonth());
	}
}
