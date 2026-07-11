/**
	Executable contract for the typed `ruby.Dir` facade.

	The calls exercise completion and static type checking while the snapshot and
	smoke gates prove that RubyHx emits ordinary `Dir.*` calls with no adapter.
**/
class Main {
	static function main():Void {
		var original = ruby.Dir.current();

		Sys.println(original.length > 0);
		Sys.println(ruby.Dir.home().length > 0);
		Sys.println(ruby.Dir.exists("std"));
		Sys.println(ruby.Dir.exists("missing-ruby-dir-facade-path"));
		Sys.println(ruby.Dir.isEmpty("std/ruby"));
		Sys.println(ruby.Dir.entries("std").indexOf(".") >= 0);
		Sys.println(ruby.Dir.children("std").indexOf("ruby") >= 0);
		Sys.println(ruby.Dir.glob("std/ruby/*.hx", 0).length > 0);

		Sys.println(ruby.Dir.changeCurrent("std"));
		Sys.println(ruby.Dir.current() == original + "/std");
		Sys.println(ruby.Dir.changeCurrent(original));
		Sys.println(ruby.Dir.current() == original);
	}
}
