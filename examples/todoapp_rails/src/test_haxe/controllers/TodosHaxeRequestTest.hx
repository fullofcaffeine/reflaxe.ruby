package test_haxe.controllers;

import app.auth.UserAuth;
import devisehx.test.IntegrationHelpers;
import models.Todo;
import models.User;
import rails.action_controller.Status;
import rails.test.Assert.*;
import rails.test.Dsl.*;
import rails.test.Request.*;
import rails.test.RequestParams;
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
			assertNoDifference(() -> Todo.count(), () -> {
				get(Routes.todosPath());
				assertResponse(Status.ok);
			});
			includes(responseBody(), "Typed Rails, polished Ruby.");
			includes(responseBody(), "Haxe Request User");
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
			assertDifference(() -> Todo.count(), 1, () -> {
				post(Routes.todosPath(), {
					params: RequestParams.model(Todo.railsParamKey, {
						title: "from haxe request",
						notes: "typed request params"
					})
				});
			});

			assertRedirectedTo(Routes.todosPath());
			equal(["from haxe request"], Todo.where({userId: user.id}).pluck(Todo.f.title));
			IntegrationHelpers.signOut(UserAuth.scope);
		});

		test("route param actions expose typed response helpers", () -> {
			var user = User.create({
				name: "Haxe Route User",
				email: "request-routes@example.test",
				role: "member",
				password: "password123",
				passwordConfirmation: "password123"
			});
			Todo.create({
				title: "haxe completed route",
				notes: "typed response helper",
				isCompleted: true,
				userId: user.id
			});

			IntegrationHelpers.signIn(UserAuth.scope, user);
			get(Routes.completedTodosPath());
			assertResponse(Status.ok);
			equal("Completed todos: haxe completed route", responseBody());

			get(Routes.filePath("docs/readme"));
			assertResponse(Status.ok);
			equal("text/plain", responseMediaType());
			equal("RailsHx file route: docs/readme\n", responseBody());
			IntegrationHelpers.signOut(UserAuth.scope);
		});
	}
}
