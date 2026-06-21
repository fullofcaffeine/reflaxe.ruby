package rails.test.playwright;

import haxe.extern.EitherType;
import js.lib.Promise;
import js.lib.RegExp;

typedef Response = {}

typedef GotoOptions = {
	@:optional var waitUntil:String;
	@:optional var timeout:Int;
}

typedef WaitForOptions = {
	@:optional var timeout:Int;
}

typedef GetByRoleOptions = {
	@:optional var name:String;
	@:optional var exact:Bool;
}

typedef Locator = {
	function click(?options:Dynamic):Promise<Void>;
	function fill(value:String):Promise<Void>;
	function count():Promise<Int>;
	function waitFor(?options:WaitForOptions):Promise<Void>;
	function nth(index:Int):Locator;
	function locator(selector:String):Locator;
	function getByText(text:String, ?options:Dynamic):Locator;
	function getByRole(role:String, ?options:GetByRoleOptions):Locator;
}

typedef Page = {
	function goto(url:String, ?options:GotoOptions):Promise<Null<Response>>;
	function locator(selector:String):Locator;
	function getByRole(role:String, ?options:GetByRoleOptions):Locator;
	function getByText(text:EitherType<String, RegExp>, ?options:Dynamic):Locator;
	function getByLabel(text:String, ?options:Dynamic):Locator;
	function url():String;
}

typedef Expectation = {
	function toBeVisible(?options:WaitForOptions):Promise<Void>;
	function toHaveCount(count:Int, ?options:WaitForOptions):Promise<Void>;
	function toContainText(value:EitherType<String, RegExp>, ?options:WaitForOptions):Promise<Void>;
	function toHaveAttribute(name:String, value:String, ?options:WaitForOptions):Promise<Void>;
}
