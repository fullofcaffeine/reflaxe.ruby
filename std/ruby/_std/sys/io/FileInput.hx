package sys.io;

import haxe.io.Bytes;
import haxe.io.Eof;
import haxe.io.Error;

/**
	Haxe file input semantics over a normal Ruby `IO` handle.

	The private extern keeps the native handle typed and limits it to byte reads,
	positioning, and lifecycle operations required by the portable API.
**/
class FileInput extends haxe.io.Input {
	final handle:RubyInputHandle;
	var reachedEof:Bool = false;

	function new(handle:RubyInputHandle) {
		this.handle = handle;
	}

	public function seek(p:Int, pos:FileSeek):Void {
		handle.seek(p, seekWhence(pos));
		reachedEof = false;
	}

	public function tell():Int {
		return handle.position();
	}

	public function eof():Bool {
		return reachedEof;
	}

	override public function readByte():Int {
		var value = handle.getByte();
		if (value == null) {
			reachedEof = true;
			throw new Eof();
		}
		return value;
	}

	override public function readBytes(bytes:Bytes, pos:Int, len:Int):Int {
		if (reachedEof) {
			throw new Eof();
		}
		if (pos < 0 || len < 0 || pos + len > bytes.length) {
			throw Error.OutsideBounds;
		}
		var remaining = len;
		try {
			while (remaining > 0) {
				bytes.set(pos++, readByte());
				remaining--;
			}
		} catch (_:Eof) {}
		return len - remaining;
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
private extern class RubyInputHandle {
	@:native("getbyte")
	function getByte():Null<Int>;

	@:native("pos")
	function position():Int;

	function seek(offset:Int, whence:Int):Int;
	function close():Void;
}
