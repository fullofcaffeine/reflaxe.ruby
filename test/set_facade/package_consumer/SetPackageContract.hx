import ruby.Set;

/** Executes from the isolated installed Haxelib to prove the Set facade ships. **/
class SetPackageContract {
	public static function verify():Void {
		var values = new Set<String>(["packaged", "packaged"]);
		values.add("typed");
		if (values.size() != 2 || !values.contains("typed")) {
			throw "packaged ruby.Set contract failed";
		}
		var combined = values.union(new Set<String>(["runtime"]));
		if (combined.size() != 3 || values.size() != 2) {
			throw "packaged ruby.Set algebra contract failed";
		}
	}
}
