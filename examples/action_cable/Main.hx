import channels.TodosChannel;
import test_haxe.channels.TodosChannelHaxeTest;

class Main {
	public static function main():Void {
		TodosChannel.announce("open", "Typed cable payload");
	}
}
