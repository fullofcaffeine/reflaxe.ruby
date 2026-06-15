require "test_helper"

class TodosControllerTest < ActionDispatch::IntegrationTest
  test "index renders the polished RailsHx todo page with ordered open work" do
    user = Models::User.create!(name: "owner")
    Models::Todo.create!(title: "zed open task", is_completed: false, user: user)
    Models::Todo.create!(title: "alpha open task", is_completed: false, user: user)
    Models::Todo.create!(title: "completed hidden task", is_completed: true, user: user)

    get "/todos"

    assert_response :success
    assert_includes @response.body, "Typed Rails, polished Ruby."
    assert_includes @response.body, "RailsHx sample"
    assert_includes @response.body, "alpha open task"
    assert_includes @response.body, "zed open task"
    assert_not_includes @response.body, "completed hidden task"
    assert_operator @response.body.index("alpha open task"), :<, @response.body.index("zed open task")
    assert_includes @response.body, "typed columns"
  end

  test "create permits haxe-authored params and ignores unpermitted fields" do
    user = Models::User.create!(name: "owner")

    assert_difference "Models::Todo.count", 1 do
      post "/todos", params: { todo: { title: "from params", notes: "typed notes", is_completed: true, user_id: user.id, ignored: "nope" } }
    end

    assert_redirected_to "/todos"
    todo = Models::Todo.order(:id).last
    assert_equal "from params", todo.title
    assert_equal "typed notes", todo.notes
    assert_not todo.is_completed
    assert_equal user, todo.user
  end

  test "create redirects without persisting invalid records" do
    user = Models::User.create!(name: "owner")

    assert_no_difference "Models::Todo.count" do
      post "/todos", params: { todo: { title: "", notes: "missing title", user_id: user.id } }
    end

    assert_redirected_to "/todos"
  end
end
