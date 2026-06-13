package rails.active_record;

/**
	Typed ActiveRecord::Relation facade.

	Methods are typed for Haxe authoring and lower to normal Rails relation calls.
**/
extern class Relation<TModel, TCriteria> {
	public function where(criteria:TCriteria):Relation<TModel, TCriteria>;
	public function rewhere(criteria:TCriteria):Relation<TModel, TCriteria>;
	@:native("or")
	public function or(other:Relation<TModel, TCriteria>):Relation<TModel, TCriteria>;
	public function merge(other:Relation<TModel, TCriteria>):Relation<TModel, TCriteria>;
	public function order(order:Order<TModel>):Relation<TModel, TCriteria>;
	public function reorder(order:Order<TModel>):Relation<TModel, TCriteria>;
	public function limit(count:Int):Relation<TModel, TCriteria>;
	public function offset(count:Int):Relation<TModel, TCriteria>;
	public function distinct():Relation<TModel, TCriteria>;
	public function select<TValue>(field:Field<TModel, TValue>):Relation<TModel, TCriteria>;
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
	public function pluck<TValue>(field:Field<TModel, TValue>):Array<TValue>;
	public function minimum<TValue>(field:Field<TModel, TValue>):Null<TValue>;
	public function maximum<TValue>(field:Field<TModel, TValue>):Null<TValue>;
	public function sum(field:Field<TModel, Int>):Int;
	public function average(field:Field<TModel, Int>):Null<Float>;

	@:native("to_a")
	public function toArray():Array<TModel>;
}
