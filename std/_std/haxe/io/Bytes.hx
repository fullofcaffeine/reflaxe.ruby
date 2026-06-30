package haxe.io;

/**
	Ruby-backed subset of `haxe.io.Bytes`.

	The byte store is intentionally modeled as an `Array<Int>` so ordinary Haxe
	std code such as `BytesBuffer` can compile first and Ruby-specific binary
	read helpers can delegate to Ruby's native `Array#pack`/`String#unpack1`.
**/
class Bytes {
	public var length(default, null):Int;

	final data:Array<Int>;

	public function new(length:Int, data:Array<Int>) {
		this.length = length;
		this.data = data;
	}

	public static function alloc(length:Int):Bytes {
		return new Bytes(length, [for (_ in 0...length) 0]);
	}

	public static function ofString(value:String, ?encoding:Encoding):Bytes {
		return new Bytes(value.length, [for (i in 0...value.length) value.charCodeAt(i)]);
	}

	public function get(pos:Int):Int {
		return data[pos] & 0xff;
	}

	public function getData():Array<Int> {
		return data;
	}

	public function set(pos:Int, value:Int):Void {
		data[pos] = value & 0xff;
	}

	public function blit(pos:Int, src:Bytes, srcpos:Int, len:Int):Void {
		for (i in 0...len) {
			set(pos + i, src.get(srcpos + i));
		}
	}

	public function sub(pos:Int, len:Int):Bytes {
		return new Bytes(len, [for (i in 0...len) get(pos + i)]);
	}

	public function getInt32(pos:Int):Int {
		return untyped __ruby__("{0}.slice({1}, 4).pack('C*').unpack1('l<')", data, pos);
	}

	public function getInt64(pos:Int):haxe.Int64 {
		return haxe.Int64.make(getInt32(pos + 4), getInt32(pos));
	}

	public function getFloat(pos:Int):Float {
		return untyped __ruby__("{0}.slice({1}, 4).pack('C*').unpack1('e')", data, pos);
	}

	public function getDouble(pos:Int):Float {
		return untyped __ruby__("{0}.slice({1}, 8).pack('C*').unpack1('E')", data, pos);
	}

	public function toString():String {
		var out = "";
		for (byte in data) {
			out += String.fromCharCode(byte);
		}
		return out;
	}
}
