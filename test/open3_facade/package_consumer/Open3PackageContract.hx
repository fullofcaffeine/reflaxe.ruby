import ruby.Open3;
import ruby.Open3Executable;

/** Installed-Haxelib contract for the complete bounded Open3 capture surface. **/
class Open3PackageContract {
	public static function verify():Void {
		var result = Open3.capture(Open3Executable.of("ruby"), "-e", "STDOUT.write('packaged-open3')");
		if (result.standardOutput != "packaged-open3"
			|| result.standardError != ""
			|| !result.status.succeeded()
			|| result.status.exitCode() != 0) {
			throw "packaged Open3 capture mismatch";
		}
	}
}
