import reflaxe.ruby.naming.RubyNaming;

class RubyNamingTestMain {
	static function main():Void {
		eq("local camel", RubyNaming.toLocalName("tempResult"), "temp_result");
		eq("local keyword", RubyNaming.toLocalName("class"), "class_");
		eq("local digit", RubyNaming.toLocalName("123abc"), "hx_123abc");
		eq("local this", RubyNaming.toLocalName("this"), "self");
		eq("method constructor", RubyNaming.toMethodName("new"), "initialize");
		eq("method keyword", RubyNaming.toMethodName("return"), "return_");
		eq("ivar self", RubyNaming.toIvarName("this"), "@self_");
		eq("constant camel", RubyNaming.toConstantName("http_client"), "HttpClient");
		eq("constant core", RubyNaming.toConstantName("class"), "Class_");
		eq("module path", RubyNaming.modulePath(["haxe", "io"]).join("."), "Haxe.Io");
		eq("file stem", RubyNaming.fileStem(["haxe", "io"], "BytesBuffer"), "haxe_io_bytes_buffer");
		eq("file name", RubyNaming.fileName("BytesBuffer"), "bytes_buffer");
		eq("file dir", RubyNaming.fileDir(["haxe", "io"]), "haxe/io");
		eq("backticks", RubyNaming.toLocalName("`end`"), "end_");
	}

	static function eq(label:String, actual:String, expected:String):Void {
		if (actual != expected) {
			throw label + ': expected "' + expected + '", got "' + actual + '"';
		}
	}
}
