import ruby.Open3Executable;

/** Compile-fail contract: callers cannot recover or mutate the private [path, argv0] array. **/
class InvalidExecutableAccess {
	static function main():Void {
		var executable = Open3Executable.of("ruby");
		var raw:Array<String> = executable;
		Sys.println(raw.length);
	}
}
