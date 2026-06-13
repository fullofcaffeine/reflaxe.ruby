// ActiveSupport typed facade tour.
//
// Demonstrates: consuming Rails/ActiveSupport receiver extensions through typed
// Haxe `using` imports rather than dynamic calls or runtime wrappers.
// Type safety: `blank()`, `present()`, and `presence()` are generic receiver
// extensions; `squish()` is limited to `String`, so applying it to another
// receiver fails in Haxe before Ruby is emitted.
// IntelliSense: editors should complete these methods after the `using`
// imports, including a `Null<T>` result for `presence()`.
// Ruby output: calls lower to direct ActiveSupport receiver methods such as
// `value.blank?()`, `value.present?()`, `value.presence()`, and
// `" a  b ".squish()` with the proper `require` lines in `run.rb`.
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
	}
}
