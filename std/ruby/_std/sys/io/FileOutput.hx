package sys.io;

import haxe.io.Bytes;
import haxe.io.Error;

/**
	Haxe file output semantics over a normal Ruby `IO` handle.

	Only byte packing crosses the typed boundary through raw Ruby because Haxe's
	`Bytes` array must become a binary-encoded Ruby String before `IO#write`.
**/
class FileOutput extends haxe.io.Output {
	final handle:RubyOutputHandle;

	function new(handle:RubyOutputHandle) {
		this.handle = handle;
	}

	public function seek(p:Int, pos:FileSeek):Void {
		handle.seek(p, seekWhence(pos));
	}

	public function tell():Int {
		return handle.position();
	}

	override public function writeByte(value:Int):Void {
		untyped __ruby__("{0}.write([{1} & 255].pack('C'))", handle, value);
	}

	override public function writeBytes(bytes:Bytes, pos:Int, len:Int):Int {
		if (pos < 0 || len < 0 || pos + len > bytes.length) {
			throw Error.OutsideBounds;
		}
		return untyped __ruby__("{0}.write({1}.get_data().slice({2}, {3}).pack('C*'))", handle, bytes, pos, len);
	}

	override public function flush():Void {
		handle.flush();
	}

	override public function close():Void {
		handle.close();
	}

	static function seekWhence(pos:FileSeek):Int {
		return switch (pos) {
			case SeekBegin: 0;
			case SeekCur: 1;
			case SeekEnd: 2;
		};
	}
}

@:native("IO")
private extern class RubyOutputHandle {
	@:native("pos")
	function position():Int;

	function seek(offset:Int, whence:Int):Int;
	function flush():Void;
	function close():Void;
}
