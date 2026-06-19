package test_haxe.models;

import models.Todo;
import models.User;
import rails.test.Assert.*;
import rails.test.Dsl.*;
import rails.test.ModelTestCase;

// Haxe-authored Rails model test.
//
// Demonstrates: `@:railsTest` materializes an ordinary Rails Minitest file
// under `test/generated`, while the source stays typed Haxe.
// Type safety: model creation uses typed field names (`isCompleted`, `userId`)
// that lower to Rails-native columns, and `Todo.f.title` makes `pluck` reject
// fields from the wrong model at Haxe compile time.
// IntelliSense: editors should complete `Todo.create`, `Todo.incomplete`,
// `Todo.f.title`, and assertion helpers such as `equal`.
// Ruby/Rails output: `test/generated/models/todo_haxe_test.rb` with
// `ActiveSupport::TestCase` methods and Minitest assertions.
@:railsTest("models/todo_haxe_test")
class TodoHaxeTest extends ModelTestCase {
	// `@:railsTests` marks a compile-time declaration host. RailsHx consumes
	// top-level `test(...)` calls here and emits idiomatic Rails `test "..." do`
	// blocks, so authors do not have to invent redundant Haxe method names.
	@:railsTests
	static function define():Void {
		test("typed incomplete scope returns typed titles", () -> {
			var user = User.create({
				name: "haxe test owner",
				email: "haxe-test-owner@example.test",
				role: "admin",
				password: "password123",
				passwordConfirmation: "password123"
			});
			Todo.create({
				title: "ship haxe tests",
				notes: "generated Minitest",
				isCompleted: false,
				userId: user.id
			});
			Todo.create({
				title: "hide completed work",
				notes: "done",
				isCompleted: true,
				userId: user.id
			});

			equal(["ship haxe tests"], Todo.incomplete().pluck(Todo.f.title));
		});
	}
}
