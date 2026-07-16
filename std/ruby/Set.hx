package ruby;

/**
	Typed Ruby-semantic facade for the native `Set` collection.

	The type parameter keeps Haxe-authored elements consistent, while Ruby still
	owns membership through `eql?` and `hash`; this is deliberately not a portable
	`haxe.ds` abstraction. Array-only construction, same-element `Set` operands,
	and typed native blocks keep the public boundary precise without wrapping the
	Ruby value or accepting arbitrary `Enumerable` inputs.

	Do not mutate an element in a way that changes its Ruby `eql?`/`hash` identity
	while it is stored. Ruby may also store a frozen copy of a mutable String.
**/
@:rubyRequire("set")
@:native("Set")
extern class Set<T> {
	/** Creates an empty set or one populated from a precisely typed Haxe Array. **/
	public function new(?values:Array<T>);

	public function size():Int;

	@:native("empty?")
	public function isEmpty():Bool;

	@:native("include?")
	public function contains(value:T):Bool;

	public function add(value:T):Set<T>;

	/** Adds `value`, returning this set only when membership changed. **/
	@:native("add?")
	public function addIfAbsent(value:T):Null<Set<T>>;

	public function delete(value:T):Set<T>;

	/** Deletes `value`, returning this set only when membership changed. **/
	@:native("delete?")
	public function deleteIfPresent(value:T):Null<Set<T>>;

	public function clear():Set<T>;

	/** Mutates this set by adding every element from `other`. **/
	public function merge(other:Set<T>):Set<T>;

	/** Mutates this set so its contents exactly match `other`. **/
	public function replace(other:Set<T>):Set<T>;

	/** Mutates this set by removing every element present in `other`. **/
	public function subtract(other:Set<T>):Set<T>;

	/** Returns a new set containing elements from either operand. **/
	public function union(other:Set<T>):Set<T>;

	/** Returns a new set containing elements common to both operands. **/
	public function intersection(other:Set<T>):Set<T>;

	/** Returns a new set without elements present in `other`. **/
	public function difference(other:Set<T>):Set<T>;

	@:native("subset?")
	public function isSubsetOf(other:Set<T>):Bool;

	@:native("proper_subset?")
	public function isProperSubsetOf(other:Set<T>):Bool;

	@:native("superset?")
	public function isSupersetOf(other:Set<T>):Bool;

	@:native("proper_superset?")
	public function isProperSupersetOf(other:Set<T>):Bool;

	@:native("intersect?")
	public function intersects(other:Set<T>):Bool;

	@:native("disjoint?")
	public function isDisjointFrom(other:Set<T>):Bool;

	/** Calls a native Ruby block once for each element and returns this set. **/
	@:native("each")
	@:rubyBlockArg
	public function forEach(block:T->Void):Set<T>;

	/** Mutates this set by deleting elements for which `predicate` is true. **/
	@:native("delete_if")
	@:rubyBlockArg
	public function deleteWhere(predicate:T->Bool):Set<T>;

	/** Mutates this set by retaining elements for which `predicate` is true. **/
	@:native("keep_if")
	@:rubyBlockArg
	public function keepWhere(predicate:T->Bool):Set<T>;

	@:native("to_a")
	public function toArray():Array<T>;
}
