package reflaxe.ruby.compiler;

import reflaxe.ruby.ast.RubyAST.RubyExpr;

/**
	Owns structural Ruby shaping for Haxe's fixed-width `haxe.Int32` contract.

	`RubyCompiler` decides when a typed Haxe value is Int32. This service then
	keeps Ruby's arbitrary-precision Integer inside the signed 32-bit range and
	masks shift counts to Haxe's low five bits. Accepting already-lowered operands
	keeps source typing out of target syntax and prevents print-and-reembed seams.
**/
class RubyInt32Lowering {
	static inline final SIGNED_OFFSET = "0x80000000";
	static inline final MODULUS = "0x100000000";
	static inline final UNSIGNED_MASK = "0xffffffff";
	static inline final SHIFT_MASK = "31";

	/** Maps one Ruby Integer into Haxe's signed two's-complement Int32 range. **/
	public static function clamp(value:RubyExpr):RubyExpr {
		return RubyBinary("-", RubyBinary("%", RubyBinary("+", value, RubyInt(SIGNED_OFFSET)), RubyInt(MODULUS)), RubyInt(SIGNED_OFFSET));
	}

	/** Applies Haxe's five-bit shift count and wraps the signed left-shift result. **/
	public static function shiftLeft(value:RubyExpr, count:RubyExpr):RubyExpr {
		return clamp(RubyBinary("<<", toInteger(value), shiftCount(count)));
	}

	/** Applies an arithmetic right shift to the signed Int32-normalized operand. **/
	public static function shiftRight(value:RubyExpr, count:RubyExpr):RubyExpr {
		return RubyBinary(">>", clamp(value), shiftCount(count));
	}

	/** Applies a logical right shift through the unsigned 32-bit representation. **/
	public static function shiftRightUnsigned(value:RubyExpr, count:RubyExpr):RubyExpr {
		return RubyBinary(">>", RubyBinary("&", toInteger(value), RubyInt(UNSIGNED_MASK)), shiftCount(count));
	}

	static function shiftCount(value:RubyExpr):RubyExpr {
		return RubyBinary("&", toInteger(value), RubyInt(SHIFT_MASK));
	}

	static function toInteger(value:RubyExpr):RubyExpr {
		return RubyCall(value, "to_i", []);
	}
}
