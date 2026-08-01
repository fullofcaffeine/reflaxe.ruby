/** Proves that a harness assertion remains a nonzero Ruby process failure. **/
class AssertionFailureMain {
	static function main():Void {
		new unit.Test().eq("intentional-expected", "intentional-actual");
	}
}
