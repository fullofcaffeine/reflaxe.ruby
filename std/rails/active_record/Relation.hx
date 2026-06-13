package rails.active_record;

/**
	Typed ActiveRecord::Relation facade.

	Methods are typed for Haxe authoring and lower to normal Rails relation calls.
**/
extern class Relation<TModel, TCriteria> {
	public function where(criteria:TCriteria):Relation<TModel, TCriteria>;
	public function order(order:Order<TModel>):Relation<TModel, TCriteria>;
	public function limit(count:Int):Relation<TModel, TCriteria>;
	public function offset(count:Int):Relation<TModel, TCriteria>;
	public function includes<TTarget>(association:Association<TModel, TTarget>):Relation<TModel, TCriteria>;
	public function joins<TTarget>(association:Association<TModel, TTarget>):Relation<TModel, TCriteria>;
	public function find(id:Dynamic):TModel;
	@:native("find_by")
	public function findBy(criteria:TCriteria):Null<TModel>;
	@:native("exists?")
	public function exists(?criteria:TCriteria):Bool;
	public function count():Int;
	public function first():Null<TModel>;
	public function last():Null<TModel>;

	@:native("to_a")
	public function toArray():Array<TModel>;
}
