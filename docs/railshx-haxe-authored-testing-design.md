# RailsHx Haxe-Authored Testing Design

RailsHx supports two first-class testing paths, and apps can choose per test:

1. Write target-native tests directly in Ruby/Rails, TypeScript, or JavaScript.
2. Write tests in Haxe and compile them to ordinary target test files.

The beginner mental model is simple: Haxe is the authoring language, Rails and
Playwright are still the runners. A Haxe-authored Rails test should feel like a
typed version of a normal Minitest/request test, then compile into a normal
`*_test.rb` file. A Haxe-authored browser test should feel like a typed version
of a normal Playwright spec, then compile through Genes into modern JavaScript
that Playwright can run.

Generated RailsHx code should look and behave like hand-written target code. A
team must be able to use ordinary Minitest, RSpec, Rails request tests, Rails
system tests, Playwright, Vitest, or any other Ruby/JS test tool without a
RailsHx-specific runtime. Haxe-authored tests are not mandatory, but they are a
canonical RailsHx path and generated RailsHx apps/scaffolds should default to
them unless the user opts out.

## Inspiration

`../haxe.elixir.codex` has an ExUnit path where:

- Haxe test modules use metadata such as `@:exunit` and `@:test`.
- Haxe test helpers type Phoenix `ConnTest` and `LiveViewTest`.
- Generated output is ordinary ExUnit test code.
- Phoenix-specific semantics stay Phoenix-specific.

RailsHx should follow that architectural lesson, not copy the Phoenix shape.
The target output for Rails is Minitest/RSpec/Rails test files and modern
JavaScript/browser test files.

## Design Goals

- Keep vanilla target-language tests always supported and mixable with
  Haxe-authored tests in the same app.
- Make Haxe-authored tests ergonomic enough that a RailsHx beginner can reach
  for them by default without losing the familiar Rails/Playwright workflow.
- Let Haxe tests reuse typed RailsHx contracts: model fields, route helpers,
  params roots, template refs, component slots, Turbo targets, DOM hooks, and
  typed client payloads.
- Emit ordinary target files that Rails and JS tools can run without RailsHx.
- Avoid raw Ruby/JS string bodies. If target-specific escape hatches are needed,
  make them explicit and searchable.
- Fail closed for filesystem-backed generation. Missing target directories,
  unsafe output paths, missing app test roots, and invalid test class names
  should be compile/generator errors.
- Preserve Rails naming and test conventions in output.

## Non-Goals

- Do not replace Rails/Minitest/RSpec.
- Do not build a custom RailsHx test runner.
- Do not hide broad Ruby tests inside JS materializer strings.
- Do not remove or discourage raw Ruby/Rails/TypeScript/JavaScript tests.
- Do not design a lowest-common-denominator portable test API that feels worse
  than Rails or Playwright. Prefer typed target facades, with shared Haxe
  contracts where they add real value.

## Layer Comparison

| Layer | Source | Output | Best For |
| --- | --- | --- | --- |
| Vanilla Rails tests | `test/**/*.rb` or `spec/**/*.rb` | Same files | Teams already using Rails test tools, migration paths, app-specific assertions. |
| Haxe-authored Rails tests | `test_haxe/**/*.hx` | `test/**/*_test.rb` or `spec/**/*_spec.rb` | Reusing typed model fields, routes, params, template refs, and RailsHx contracts. |
| Vanilla JS/browser tests | `e2e/**/*.spec.ts`, `test/**/*.test.ts` | Same files | Existing Playwright/Vitest suites. |
| Haxe-authored JS/browser tests | `test_haxe_js/**/*.hx` or `e2e_haxe/**/*.hx` | Playwright/Vitest-compatible `.spec.ts`/`.test.ts` or compiled JS | Reusing typed DOM hooks, Turbo event contracts, route constants, and client payloads. |

## Beginner Quick Start

If you are new to RailsHx testing, start with this rule of thumb:

- Use Haxe when the test touches Haxe-owned app contracts: model fields,
  generated route helpers, strong params, HHX template refs, DeviseHx scopes,
  Turbo targets, shared DOM hooks, or typed payloads.
- Use raw Ruby/Rails or TypeScript/JavaScript when the test is clearer in the
  target language, especially for Rails-owned fixtures, gem-owned behavior,
  migration-path checks, or a tiny browser assertion with no shared Haxe
  contracts.

For a Rails model or request test, write Haxe under `test_haxe/**`:

```haxe
import models.Todo;
import models.User;
import rails.test.Assert.*;
import rails.test.Dsl.*;
import rails.test.ModelTestCase;

@:railsTest("models/todo_haxe_test")
class TodoHaxeTest extends ModelTestCase {
	@:railsTests
	static function define():Void {
		test("incomplete returns only open todos", () -> {
			var user = User.create({name: "owner"});
			Todo.create({title: "ship", isCompleted: false, userId: user.id});
			Todo.create({title: "done", isCompleted: true, userId: user.id});

			assertEqual(["ship"], Todo.incomplete().pluck(Todo.f.title));
		});
	}
}
```

Then run the normal RailsHx test task:

```bash
bundle exec rake hxruby:test
```

Rails still runs generated Ruby/Minitest output under `test/generated/**`.

For a browser test, write Haxe under `e2e_haxe/**` and compile through Genes:

```haxe
import js.lib.Promise;
import rails.test.playwright.Playwright.PW;
import rails.test.playwright.Types.Page;
import reflaxe.js.Async;
import reflaxe.js.Async.await;
import shared.TodoHooks;

PW.testPage("guest reaches the board", Async.async(function(page:Page):Promise<Void> {
	await(page.goto("/todos"));
	await(page.getByRole("button", {name: "Continue as guest"}).click());
	await(PW.see(page.locator(TodoHooks.classSelector(TodoHooks.shellClass))).toBeVisible());
	return Promise.resolve(null);
}));
```

Playwright still runs generated JavaScript from `e2e/generated/**`.

## API Map

| Haxe authoring API | Target output idea |
| --- | --- |
| `test("...", () -> {...})` | Rails `test "..." do ... end` |
| `setup(() -> {...})` / `teardown(() -> {...})` | Minitest setup/teardown blocks |
| `assertResponse(Status.ok)` | `assert_response :ok` |
| `assertRedirectedTo(Routes.todosPath())` | `assert_redirected_to "/todos"` |
| `get(Routes.todosPath())` | `get "/todos"` |
| `post(path, {params: RequestParams.model(...)})` | ActionDispatch request with Rails params hash |
| `Todo.f.title`, `Todo.railsParamKey` | Rails symbols/param roots such as `:title`, `todo` |
| `PW.testPage("...", page -> ...)` | Playwright `test("...", async ({ page }) => ...)` |
| `TodoHooks.*` in browser tests | Shared selectors/ids/data attrs exported from Haxe |

## Current API Audit

The current Rails test surface is enough for model tests, request tests, basic
setup/teardown, typed request params, DeviseHx integration helpers, and common
assertions. That is the minimum viable RailsHx path for generated app/scaffold
tests to default to Haxe-authored source.

The current browser test surface is intentionally small: Haxe specs compile
through Genes, `PW.testPage(...)` hides Playwright's fixture-destructuring
interop, and typed `Page`/`Locator`/`Expectation` externs cover the todoapp
sentinel. This proves the path without replacing Playwright.

Follow-up ergonomic gaps should be tracked as focused beads before widening
APIs:

- Rails fixtures/factories: typed fixture lookup or typed FactoryBot wrappers.
- Request params: richer nested/non-model builders beyond `RequestParams.model`.
- Assertions: more Rails/Minitest helpers where examples currently need raw
  Ruby-shaped checks.
- Browser tests: typed helpers for common Playwright waits, route assertions,
  Turbo lifecycle waits, and shared hook exports.
- Output modes: decide later whether Haxe-authored browser tests need direct
  TypeScript output, or whether Genes ES modules remain the preferred lane.

## Rails Test API Shape

The first Rails test slice should target Minitest because Rails ships with it
and the todoapp already uses it.

Example source:

```haxe
package test.models;

import rails.test.ModelTestCase;
import rails.test.Assert.*;
import rails.test.Dsl.*;
import models.Todo;
import models.User;

@:railsTest("models/todo_test")
class TodoTest extends ModelTestCase {
	@:railsTests
	static function define():Void {
		test("incomplete returns incomplete todos", () -> {
			var user = User.create({name: "owner"});
			Todo.create({title: "ship ruby", isCompleted: false, user: user});
			Todo.create({title: "done", isCompleted: true, user: user});

			assertEqual(["ship ruby"], Todo.incomplete().pluck(Todo.f.title));
		});

		test("validates required title", () -> {
			var user = User.create({name: "owner"});
			var todo = Todo.build({user: user, notes: "missing title", isCompleted: false});

			assertFalse(todo.valid());
			assertIncludes(todo.errors().get(Todo.f.title), "can't be blank");
		});
	}
}
```

Possible generated Minitest:

```ruby
require "test_helper"

class TodoTest < ActiveSupport::TestCase
  test "incomplete returns incomplete todos" do
    user = Models::User.create!(name: "owner")
    Models::Todo.create!(title: "ship ruby", is_completed: false, user: user)
    Models::Todo.create!(title: "done", is_completed: true, user: user)

    assert_equal ["ship ruby"], Models::Todo.incomplete.pluck(:title)
  end

  test "validates required title" do
    user = Models::User.create!(name: "owner")
    todo = Models::Todo.new(user: user, notes: "missing title", is_completed: false)

    assert_not todo.valid?
    assert_includes todo.errors[:title], "can't be blank"
  end
end
```

`@:railsTests static function define():Void` is the canonical RailsHx test
declaration host. It is legal Haxe, editor-friendly, and compiler-erased: the
function itself is never emitted. Top-level `rails.test.Dsl.test/setup/teardown`
calls inside it become Rails-native Minitest blocks.

The older method form remains supported for compatibility and for users who
prefer one Haxe function per test:

```haxe
@:railsTest("models/todo_test")
class TodoTest extends ModelTestCase {
	@:test("validates required title")
	public function validatesRequiredTitle():Void {
		// typed Haxe body
	}
}
```

Helper methods in `@:railsTest` classes are not tests unless explicitly marked
with `@:test`; this keeps ordinary helper extraction safe.

The Haxe API should prefer Rails-shaped concepts but typed RailsHx refs:

- `Todo.f.title` instead of `:title` where the field is model-owned.
- `Routes.todosPath()` instead of `"/todos"` where route helpers exist.
- `Template.of(TodoIndexView)` where a template identity matters.
- `Todo.railsParamKey` and typed params objects for request payload helpers.

## Rails Request Test API Shape

Example source:

```haxe
package test.controllers;

import rails.action_controller.Status;
import rails.test.RequestTestCase;
import rails.test.Assert.*;
import rails.test.Request.*;
import rails.test.RequestParams;
import models.Todo;
import models.User;
import routes.Routes;

@:railsTest("controllers/todos_controller_test")
class TodosControllerTest extends RequestTestCase {
	@:railsTests
	static function define():Void {
		test("create permits typed params and redirects", () -> {
			var user = User.create({name: "owner"});

			assertDifference(() -> Todo.count(), 1, () -> {
				post(Routes.todosPath(), {
					todo: Todo.params({
						title: "from params",
						notes: "typed notes",
						isCompleted: true,
						userId: user.id
					})
				});
			});

			assertRedirectedTo(Routes.todosPath());
			var todo = Todo.order(Todo.f.id.asc()).last();
			assertEqual("from params", todo.title);
			assertFalse(todo.isCompleted);
		});
	}
}
```

The first implemented request helper slice exposes `rails.test.Request.get`,
`post`, `patch`, and `delete` as compiler-erased Haxe calls. These lower to
ordinary ActionDispatch request helpers and accept a Rails-shaped options object:

```haxe
get(Routes.todosPath());
assertResponse(Status.ok);

post(Routes.todosPath(), {
	params: RequestParams.model(Todo.railsParamKey, {
		title: "from haxe request",
		notes: "typed request params"
	})
});
assertRedirectedTo(Routes.todosPath());
```

`RequestParams.model(Todo.railsParamKey, {...})` validates that the object keys
are real `@:railsColumn` fields on `Todo`, then lowers to a normal Rails params
hash with the model root and snake_case column keys.

`assertDifference(() -> Todo.count(), 1, () -> { ... })` and
`assertNoDifference(() -> Todo.count(), () -> { ... })` lower to Rails'
native `assert_difference` / `assert_no_difference` block helpers with typed
Haxe model/query expressions inside the measurement lambdas.

Route helpers, model refs, assertions, and Devise test helper scopes remain
typed Haxe inputs; Rails still receives normal Minitest/ActionDispatch output.
Richer nested/non-model request-param builders remain follow-up work under
`haxe.ruby-skz`.

Possible generated Minitest:

```ruby
class TodosControllerTest < ActionDispatch::IntegrationTest
  test "create permits typed params and redirects" do
    user = Models::User.create!(name: "owner")

    assert_difference "Models::Todo.count", 1 do
      post "/todos", params: {
        todo: {
          title: "from params",
          notes: "typed notes",
          is_completed: true,
          user_id: user.id
        }
      }
    end

    assert_redirected_to "/todos"
    todo = Models::Todo.order(id: :asc).last
    assert_equal "from params", todo.title
    assert_not todo.is_completed
  end
end
```

## JS And Browser Test API Shape

The first browser slice targets Playwright-compatible JavaScript emitted by the
existing Haxe-to-JS + Genes ES-module lane. Vanilla TypeScript Playwright specs
remain first-class; Haxe-authored browser tests are the canonical RailsHx typed
authoring path for specs that benefit from typed RailsHx hooks, route constants,
Turbo contracts, or shared client payloads.

Example source:

```haxe
package e2e;

import js.lib.Promise;
import rails.test.playwright.Playwright.PW;
import rails.test.playwright.Types.Page;
import reflaxe.js.Async;
import reflaxe.js.Async.await;
import shared.TodoHooks;

class TodoBrowserTest {
	static function main():Void {
		PW.testPage("creates a task through Turbo/importmap-backed Rails form flow", Async.async(function(page:Page):Promise<Void> {
			await(page.goto("/todos"));
			await(PW.see(page.locator(TodoHooks.classSelector(TodoHooks.shellClass))).toBeVisible());

			await(page.getByLabel("What should ship next?").fill("Typed browser test"));
			await(page.getByLabel("Why does it matter?").fill("Haxe reused shared hooks."));
			await(page.getByRole("button", {name: "Add task"}).click());

			await(PW.see(page.getByText("Task added to open work")).toBeVisible());
			return Promise.resolve(null);
		}));
	}
}
```

Generated Playwright-compatible JavaScript is ordinary ES module output:

```js
import * as PlaywrightApi from "@playwright/test";

PlaywrightApi.test("creates a task through Turbo/importmap-backed Rails form flow", async function ({ page }) {
  await page.goto("/todos");
  await PlaywrightApi.expect(page.locator(".todo-shell")).toBeVisible();
});
```

The `rails.test.playwright.PW` facade owns the one JavaScript interop seam
Playwright requires: fixture destructuring (`async ({ page }) => ...`). App
tests call `PW.testPage(name, page -> ...)`, keep typed `Page`/`Locator`
completion, and use `Async.async(...)` so Genes emits a native async callback.
If direct TypeScript emission becomes necessary later, it should be a narrow
test-output mode with snapshots rather than the default browser-test path.

## Output Ownership

Haxe-authored tests should have explicit output roots:

- Rails tests: `test/generated/**/*_test.rb` by default.
- RSpec, if supported later: `spec/generated/**/*_spec.rb`.
- Playwright tests: Genes emits the module tree under
  `e2e/generated/<suite>/`, and the runner writes a tiny disposable
  `e2e/generated/<suite>.spec.js` wrapper that imports the real entry so
  Playwright's default discovery sees it. The generated
  `e2e/generated/package.json` contains `{ "type": "module" }`. Direct `.ts`
  emission remains a possible future mode.

Generated test files should be safe to delete and regenerate. User-authored
vanilla tests should live outside generated roots and must never be overwritten.

## Todoapp Migration Path

The todoapp should keep its current vanilla Rails fixtures:

- `examples/todoapp_rails/rails/test/models/todo_test.rb`
- `examples/todoapp_rails/rails/test/models/user_test.rb`
- `examples/todoapp_rails/rails/test/controllers/todos_controller_test.rb`
- `examples/todoapp_rails/e2e/todoapp.spec.ts`

The first Haxe-authored test example should live alongside them, not replace
them:

- `examples/todoapp_rails/test_haxe/models/TodoTest.hx`
- `examples/todoapp_rails/test_haxe/controllers/TodosControllerTest.hx`
- `examples/todoapp_rails/e2e_haxe/TodoappBrowserSpec.hx`

The materializer should copy vanilla tests and generated tests into the
disposable Rails app. This lets reviewers compare the vanilla and Haxe-authored
forms while Rails still executes ordinary test files.

## Implementation Plan

1. Add design-only examples and snapshots for Haxe-authored Rails test output.
2. Implement minimal `rails.test.Assert`, `rails.test.Dsl`, and
   `rails.test.ModelTestCase`.
3. Implement `@:railsTest("path")` lowering to Minitest files under
   `test/generated`, with `@:railsTests static function define():Void` as the
   canonical compiler-erased declaration host and explicit `@:test` methods as
   compatibility.
4. Add request-test helpers: `get`, `post`, `assertResponse`,
   `assertRedirectedTo`, `assertDifference`, and `assertNoDifference`.
5. Add todoapp Haxe-authored tests in parallel with the existing Ruby fixtures.
6. Add Playwright Haxe authoring through Genes ES-module output; keep vanilla
   TypeScript specs fully supported in parallel.

## Open Questions

- Whether RSpec should be a first-class output mode or an extension after
  Minitest.
- Whether Haxe-authored Playwright needs a later TypeScript output mode for
  richer editor integration, or whether Haxe-to-JS plus typed externs remains
  sufficient.
- How much Rails fixture/factory support belongs in RailsHx versus external
  typed wrappers for FactoryBot, fixtures, or fixtures-like builders.
- Whether generated test output should be checked into app repos by default or
  treated like build output. RailsHx examples should commit snapshots here, but
  generated user app policy may differ.
