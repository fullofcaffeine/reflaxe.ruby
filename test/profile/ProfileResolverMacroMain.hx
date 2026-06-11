#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import reflaxe.ruby.ProfileResolver;
#end

class ProfileResolverMacroMain {
	#if macro
	public static macro function assertProfile(expected:String):Expr {
		var actual:String = ProfileResolver.resolve();
		if (actual != expected) {
			Context.fatalError('Expected Ruby profile "' + expected + '", got "' + actual + '"', Context.currentPos());
		}
		return macro null;
	}
	#end

	static function main():Void {}
}
