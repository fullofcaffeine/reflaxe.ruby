import test_haxe.controllers.AdapterRequestHaxeSpec;
import test_haxe.models.AdapterModelHaxeSpec;
import test_haxe.models.AdapterModelHaxeTest;

class Main {
	static function main():Void {
		var minitest:Class<AdapterModelHaxeTest> = AdapterModelHaxeTest;
		var rspecModel:Class<AdapterModelHaxeSpec> = AdapterModelHaxeSpec;
		var rspecRequest:Class<AdapterRequestHaxeSpec> = AdapterRequestHaxeSpec;
		Sys.println(minitest != null && rspecModel != null && rspecRequest != null);
	}
}
