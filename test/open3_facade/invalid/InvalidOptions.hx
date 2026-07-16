import ruby.Open3;
import ruby.Open3Executable;

/** Compile-fail contract: open process-option objects are outside the string argv surface. **/
class InvalidOptions {
	static function main():Void {
		Open3.capture(Open3Executable.of("ruby"), {chdir: "/tmp"});
	}
}
