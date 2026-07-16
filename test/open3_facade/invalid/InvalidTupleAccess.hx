import ruby.Open3;
import ruby.Open3Executable;

/** Compile-fail contract: the native heterogeneous tuple remains property-only and opaque. **/
class InvalidTupleAccess {
	static function main():Void {
		var result = Open3.capture(Open3Executable.of("ruby"), "-e", "exit 0");
		var raw:Array<String> = result;
		Sys.println(raw.length);
	}
}
