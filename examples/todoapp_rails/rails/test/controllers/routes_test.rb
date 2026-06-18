require "test_helper"

class RoutesTest < ActionDispatch::IntegrationTest
  test "haxe owned routes dispatch through ordinary Rails routing" do
    # These routes are authored in src_haxe/routes/AppRoutes.hx with typed
    # controller/action refs such as to(TodosController, index). The compiler
    # emits config/routes.rb, then Rails remains the runtime oracle here.
    assert_routing({ path: "/", method: :get }, { controller: "controllers/todos", action: "index" })
    assert_recognizes({ controller: "controllers/todos", action: "index" }, { path: "/todos", method: :get })
    assert_recognizes({ controller: "controllers/todos", action: "create" }, { path: "/todos", method: :post })
    assert_recognizes({ controller: "controllers/todos", action: "completed" }, { path: "/todos/completed", method: :get })
    assert_recognizes({ controller: "controllers/todos", action: "complete", id: "42" }, { path: "/todos/42/complete", method: :patch })
    assert_routing({ path: "/users", method: :get }, { controller: "controllers/users", action: "index" })
    assert_routing({ path: "/session", method: :post }, { controller: "controllers/sessions", action: "create" })
    assert_routing({ path: "/session", method: :delete }, { controller: "controllers/sessions", action: "destroy" })
    assert_recognizes({ controller: "controllers/todos", action: "optional_report", year: "2026" }, { path: "/reports/2026", method: :get })
    assert_recognizes({ controller: "controllers/todos", action: "optional_report" }, { path: "/reports", method: :get })
    assert_recognizes({ controller: "controllers/todos", action: "file", path: "docs/readme" }, { path: "/files/docs/readme", method: :get })
  end

  test "generated route helpers match haxe route externs" do
    # src_haxe/routes/Routes.hx exposes typed externs for these helpers. Ruby
    # code sees the same helpers Rails would expose for a hand-written route
    # file, which keeps Haxe-owned and Rails-owned call sites interoperable.
    assert_equal "/", root_path
    assert_equal "/todos", todos_path
    assert_equal "/users", users_path
    assert_equal "/session", sign_in_path
    assert_equal "/session", sign_out_path
    assert_equal "/todos/completed", completed_todos_path
    assert_equal "/todos/42/complete", complete_todo_path(42)
    assert_equal "/admin/users", admin_users_path
    assert_equal "/reports", optional_report_path
    assert_equal "/files/docs/readme", file_path("docs/readme")
  end

  test "rails owned adoption route remains consumable beside haxe owned routes" do
    # This route comes from rails/config/routes_rails_owned.rb, not AppRoutes.hx.
    # It models a gradual-adoption app where a Rails-owned route remains in
    # Ruby, while Haxe consumes its generated helper through Routes.legacyHealthPath().
    assert_equal "/rails-owned-health", legacy_health_path

    get legacy_health_path

    assert_response :success
    assert_equal "rails-owned route\n", @response.body
  end
end
