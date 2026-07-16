import ruby.Set;

/**
	Executable contract for the typed Ruby-semantic `ruby.Set<T>` facade.

	The sample exercises duplicate removal, precise changed-result nullability,
	mutation, same-element algebra and relations, typed native blocks, and explicit
	Array conversion. Generated Ruby should contain one `require "set"`, direct
	`Set.new(...)` construction, and ordinary receiver calls without a wrapper.
**/
class Main {
	static function main():Void {
		var empty = new Set<String>();
		Sys.println(empty.isEmpty());

		var values = new Set<String>(["alpha", "beta", "alpha"]);
		Sys.println(values.size());
		Sys.println(values.isEmpty());
		Sys.println(values.contains("alpha"));
		Sys.println(values.contains("missing"));
		Sys.println(values.addIfAbsent("alpha") == null);
		Sys.println(values.addIfAbsent("gamma") != null);
		Sys.println(values.deleteIfPresent("missing") == null);
		Sys.println(values.deleteIfPresent("gamma") != null);

		var visited:Array<String> = [];
		values.forEach(function(value) {
			visited.push(value);
		});
		printValues(visited);

		var left = new Set<String>(["alpha", "beta"]);
		var right = new Set<String>(["beta", "gamma"]);
		printSet(left.union(right));
		printSet(left.intersection(right));
		printSet(left.difference(right));
		printSet(left);
		Sys.println(left.intersects(right));
		Sys.println(left.isDisjointFrom(new Set<String>(["delta"])));

		var alphaOnly = new Set<String>(["alpha"]);
		Sys.println(alphaOnly.isSubsetOf(left));
		Sys.println(alphaOnly.isProperSubsetOf(left));
		Sys.println(left.isSupersetOf(alphaOnly));
		Sys.println(left.isProperSupersetOf(alphaOnly));

		var filtered = new Set<String>(["alpha", "beta", "gamma"]);
		filtered.deleteWhere(value -> value == "beta");
		filtered.keepWhere(value -> value != "gamma");
		printSet(filtered);

		var mutable = new Set<String>(["alpha"]);
		mutable.add("beta");
		mutable.merge(new Set<String>(["gamma"]));
		mutable.subtract(new Set<String>(["beta"]));
		printSet(mutable);
		mutable.replace(new Set<String>(["replacement"]));
		printSet(mutable);
		mutable.delete("replacement");
		Sys.println(mutable.isEmpty());
		mutable.add("again");
		mutable.clear();
		Sys.println(mutable.size());
	}

	static function printSet(values:Set<String>):Void {
		printValues(values.toArray());
	}

	static function printValues(values:Array<String>):Void {
		values.sort(function(left, right) {
			return left == right ? 0 : (left < right ? -1 : 1);
		});
		Sys.println(values.join(","));
	}
}
