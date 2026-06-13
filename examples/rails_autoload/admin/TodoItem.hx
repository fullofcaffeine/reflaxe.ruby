package admin;

// Rails autoloaded class fixture.
//
// Demonstrates: Haxe package `admin` lowers to Ruby module `Admin` in Rails
// mode. This is intentionally tiny so the smoke focuses on path/constant shape.
// Type safety/IntelliSense: `title` is a typed `String` field visible to Haxe
// callers; generated Ruby exposes normal accessors for Rails/Ruby callers.
class TodoItem {
	public var title:String;
}
