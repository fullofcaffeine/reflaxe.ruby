import views.ComponentCardView;
import views.ComponentShellView;

class Main {
	public static function main():Void {
		var card:Class<ComponentCardView> = ComponentCardView;
		var shell:Class<ComponentShellView> = ComponentShellView;
		Sys.println(card != null && shell != null);
	}
}
