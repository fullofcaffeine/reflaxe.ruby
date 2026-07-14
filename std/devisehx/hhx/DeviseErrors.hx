package devisehx.hhx;

#if macro
import devisehx.macros.ContractTools;
import haxe.macro.Expr;
#end

/** Typed Devise/ActiveModel error reads for HHX templates. **/
@:rubyNoEmit
class DeviseErrors {
	public static macro function hasAny(resource:Expr):Expr {
		#if macro
		ContractTools.requireDeviseResource(resource);
		return ContractTools.checked(macro @:pos(resource.pos) devisehx.macros.RubyFragments.value1("{0}.errors.any?", $resource), macro :Bool);
		#else
		return macro null;
		#end
	}

	public static macro function count(resource:Expr):Expr {
		#if macro
		ContractTools.requireDeviseResource(resource);
		return ContractTools.checked(macro @:pos(resource.pos) devisehx.macros.RubyFragments.value1("{0}.errors.count", $resource), macro :Int);
		#else
		return macro null;
		#end
	}

	public static macro function fullMessages(resource:Expr):Expr {
		#if macro
		ContractTools.requireDeviseResource(resource);
		return ContractTools.checked(macro @:pos(resource.pos) devisehx.macros.RubyFragments.value1("{0}.errors.full_messages", $resource),
			macro :Array<String>);
		#else
		return macro null;
		#end
	}
}
