package rails.active_record;

/**
	Typed ActiveRecord::Relation facade.

	Methods are typed for Haxe authoring and lower to normal Rails relation calls.
**/
extern class Relation<TModel> {
	public function where(criteria:Dynamic):Relation<TModel>;
	public function order(order:Order<TModel>):Relation<TModel>;
	public function limit(count:Int):Relation<TModel>;
	public function find(id:Dynamic):TModel;
	@:native("find_by")
	public function findBy(criteria:Dynamic):Null<TModel>;
	public function first():Null<TModel>;

	@:native("to_a")
	public function toArray():Array<TModel>;
}
