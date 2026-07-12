/** Concern variant proves copied extension contracts preserve the same ABI. **/
@:rubyConcern("CallableConcern")
class CallableConcern {
	@:rubyBlockArg
	public function concernVisit(value:Int, block:Int->String):String {
		return block(value);
	}
}
