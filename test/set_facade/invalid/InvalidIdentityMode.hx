import ruby.Set;

class InvalidIdentityMode {
	static function main():Void {
		var values = new Set<String>(["typed"]);
		values.compareByIdentity();
	}
}
