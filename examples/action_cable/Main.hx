import channels.TodosChannel;

class Main {
	public static function main():Void {
		TodosChannel.announce("open", "Typed cable payload");
	}
}
