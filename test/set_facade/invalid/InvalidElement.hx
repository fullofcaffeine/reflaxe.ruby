import ruby.Set;

class InvalidElement {
	static function main():Void {
		var values = new Set<String>(["typed"]);
		values.add(1);
	}
}
