package;

class Sys {
	public static function print(value:Dynamic):Void {}

	public static function println(value:Dynamic):Void {}

	public static function args():Array<String> {
		return [];
	}

	public static function getEnv(name:String):Null<String> {
		return null;
	}

	public static function putEnv(name:String, value:Null<String>):Void {}

	public static function environment():Map<String, String> {
		return new Map();
	}

	public static function getCwd():String {
		return "";
	}

	public static function setCwd(path:String):Void {}

	public static function systemName():String {
		return "Ruby";
	}

	public static function command(cmd:String, ?args:Array<String>):Int {
		return 0;
	}

	public static function exit(code:Int):Void {}

	public static function time():Float {
		return 0.0;
	}

	public static function cpuTime():Float {
		return time();
	}

	public static function sleep(seconds:Float):Void {}

	public static function setTimeLocale(locale:String):Bool {
		return false;
	}
}
