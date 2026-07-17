// ActiveSupport typed facade tour.
//
// Demonstrates: consuming Rails/ActiveSupport receiver extensions through typed
// Haxe `using` imports rather than dynamic calls or runtime wrappers.
// Type safety: `blank()`, `present()`, and `presence()` are generic receiver
// extensions; `squish()` is limited to `String`, so applying it to another
// receiver fails in Haxe before Ruby is emitted.
// It also demonstrates Rails' modern zoned-time path: RailsTime selects the
// application zone, TimeZone constructs values, and TimeWithZone exposes typed
// components and conversion without using deprecated Ruby DateTime.
// IntelliSense: editors should complete the receiver extensions after the
// `using` imports, including a `Null<T>` result for `presence()`, and expose
// precise TimeZone/TimeWithZone results without Dynamic.
// Ruby output: calls lower to direct ActiveSupport receiver methods such as
// `value.blank?()`, `value.present?()`, `value.presence()`, and
// `" a  b ".squish()`, plus ordinary `Time.find_zone!`, `Time.current`,
// `Time.zone`, and zoned receiver calls with proper `require` lines in run.rb.
import rails.active_support.RailsTime;

using rails.active_support.ObjectPresence;
using rails.active_support.StringFilters;

class Main {
	static function main() {
		var title = "  Ship   typed   Rails  ";
		var normalized = title.squish();
		var maybeTitle = normalized.presence();

		Sys.println("".blank());
		Sys.println(normalized.present());
		Sys.println(maybeTitle != null);
		Sys.println(normalized);

		var zone = RailsTime.findZoneRequired("America/New_York");
		var local = zone.local(2026, 7, 17, 12, 30, 0);
		var fromEpoch = zone.at(local.toUtc().toEpochSeconds());
		var fromIso = zone.parseIso8601("2026-07-17T12:30:00-04:00");
		var fromRfc3339 = zone.parseRfc3339("2026-07-17T16:30:00Z");
		var later = local.addSeconds(90.5);

		Sys.println(zone.name());
		Sys.println(zone.standardName());
		Sys.println(zone.baseUtcOffsetSeconds());
		Sys.println(zone.formattedOffset());
		Sys.println(local.year());
		Sys.println(local.month());
		Sys.println(local.day());
		Sys.println(local.hour());
		Sys.println(local.minute());
		Sys.println(local.second());
		Sys.println(local.zone());
		Sys.println(local.timeZone().name());
		Sys.println(local.isDaylightSavingTime());
		Sys.println(local.isUtc());
		Sys.println(local.utcOffsetSeconds());
		Sys.println(local.formattedOffset(false));
		Sys.println(local.toIso8601());
		Sys.println(local.strftime("%Y-%m-%d %H:%M:%S %:z"));
		Sys.println(local.toTime().strftime("%Y-%m-%d %H:%M:%S %z"));
		Sys.println(fromEpoch.toIso8601());
		Sys.println(fromIso.toIso8601());
		Sys.println(fromRfc3339.toIso8601());
		Sys.println(later.toIso8601(3));
		Sys.println(later.secondsSince(local));
		Sys.println(later.subtractSeconds(90.5).toIso8601());
		Sys.println(zone.today().year() > 0);
		Sys.println(RailsTime.findZone("Not/A_Real_Zone") == null);
		Sys.println(RailsTime.zone().name());
		Sys.println(RailsTime.current().timeZone().name());
	}
}
