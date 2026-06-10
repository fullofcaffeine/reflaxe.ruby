package haxe.io;

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
		return data[pos];
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

	public function toString():String {
		var out = "";
		for (byte in data) {
			out += String.fromCharCode(byte);
		}
		return out;
	}
}
