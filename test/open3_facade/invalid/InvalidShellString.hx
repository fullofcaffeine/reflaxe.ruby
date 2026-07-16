import ruby.Open3;

/** Compile-fail contract: unchecked shell command strings are not executable identities. **/
class InvalidShellString {
	static function main():Void {
		Open3.capture("printf unsafe");
	}
}
