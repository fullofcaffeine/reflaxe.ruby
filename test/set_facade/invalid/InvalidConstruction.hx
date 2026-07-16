import ruby.Set;

class InvalidConstruction {
	static function main():Void {
		var values = new Set<String>([1]);
		Sys.println(values.size());
	}
}
