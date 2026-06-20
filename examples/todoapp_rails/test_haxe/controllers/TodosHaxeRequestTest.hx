package test_haxe.controllers;

import app.auth.UserAuth;
import devisehx.test.IntegrationHelpers;
import models.Todo;
import models.User;
import rails.action_controller.Status;
import rails.test.Assert.*;
import rails.test.Dsl.*;
import rails.test.Request.*;
import rails.test.RequestTestCase;
import routes.Routes;

// Haxe-authored Rails request test.
//
// Demonstrates: typed request helpers lower to ordinary ActionDispatch calls
// (`get`, `post`, `assert_response`, `assert_redirected_to`) while the test
// still reuses typed Devise scopes and generated route/model refs.
// Type safety: `UserAuth.scope`, `Routes.todosPath`, `Todo.where`, and
// `Todo.f.title` are compile-time checked; the generated Ruby stays vanilla
// Rails/Minitest and includes Devise's native integration helpers.
@:railsTest("controllers/todos_haxe_request_test")
class TodosHaxeRequestTest extends RequestTestCase {
	@:railsTests
	static function define():Void {
		test("signed-in users can view their board", () -> {
			var user = User.create({
				name: "Haxe Request User",
				email: "request-viewer@example.test",
				role: "member",
				password: "password123",
				passwordConfirmation: "password123"
			});

			IntegrationHelpers.signIn(UserAuth.scope, user);
			get(Routes.todosPath());

			assertResponse(Status.ok);
			IntegrationHelpers.signOut(UserAuth.scope);
		});

		test("create accepts typed route and request params", () -> {
			var user = User.create({
				name: "Haxe Request User",
				email: "request-creator@example.test",
				role: "member",
				password: "password123",
				passwordConfirmation: "password123"
			});

			IntegrationHelpers.signIn(UserAuth.scope, user);
			post(Routes.todosPath(), {
				params: {
					todo: {
						title: "from haxe request",
						notes: "typed request params"
					}
				}
			});

			assertRedirectedTo(Routes.todosPath());
			equal(["from haxe request"], Todo.where({userId: user.id}).pluck(Todo.f.title));
			IntegrationHelpers.signOut(UserAuth.scope);
		});
	}
}
