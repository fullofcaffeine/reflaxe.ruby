package;

class ClientMain {
	static function main():Void {
		var stream:String = RoomContract.streamName();
		var target:String = RoomContract.streamTarget();
		var template = RoomContract.rowTemplate();
		js.Browser.console.log(stream + ":" + target + ":" + template.templatePath);
	}
}
