import ruby.Set;

class InvalidEnumerable {
	static function main():Void {
		var values = new Set<String>(["typed"]);
		values.merge(["array-is-not-a-set"]);
	}
}
