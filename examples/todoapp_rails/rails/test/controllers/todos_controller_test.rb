require "test_helper"

class TodosControllerTest < ActionDispatch::IntegrationTest
  test "index renders the polished RailsHx todo page with ordered open work" do
    user = Models::User.create!(name: "owner", email: "owner@example.test", role: "admin")
    Models::User.create!(name: "member", email: "member@example.test", role: "member")
    Models::Todo.create!(title: "zed open task", is_completed: false, user: user)
    Models::Todo.create!(title: "alpha open task", is_completed: false, user: user)
    Models::Todo.create!(title: "completed hidden task", is_completed: true, user: user)
    Models::ChatMessage.create!(body: "typed chat note", user: user)

    get "/todos"

    assert_response :success
    assert_includes @response.body, "Typed Rails, polished Ruby."
    assert_includes @response.body, "RailsHx sample"
    assert_includes @response.body, "Typed session layer"
    assert_includes @response.body, "owner@example.test"
    assert_includes @response.body, "Manage users"
    assert_includes @response.body, "Typed Turbo room"
    assert_includes @response.body, "typed chat note"
    assert_includes @response.body, "alpha open task"
    assert_includes @response.body, "zed open task"
    assert_not_includes @response.body, "completed hidden task"
    assert_operator @response.body.index("alpha open task"), :<, @response.body.index("zed open task")
    assert_includes @response.body, "typed columns"
  end

  test "create permits haxe-authored params and ignores unpermitted fields" do
    user = Models::User.create!(name: "owner", email: "owner-create@example.test", role: "admin")

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
    user = Models::User.create!(name: "owner", email: "owner-invalid@example.test", role: "admin")

    assert_no_difference "Models::Todo.count" do
      post "/todos", params: { todo: { title: "", notes: "missing title", user_id: user.id } }
    end

    assert_redirected_to "/todos"
  end

  test "session create stores the selected user id and redirects" do
    user = Models::User.create!(name: "session owner", email: "session@example.test", role: "maintainer")

    post "/session", params: { user: { id: user.id } }

    assert_redirected_to "/todos"
    assert_equal user.id, session[:current_user_id]
  end

  test "session destroy clears the selected user id and redirects" do
    user = Models::User.create!(name: "session owner", email: "session-clear@example.test", role: "maintainer")
    post "/session", params: { user: { id: user.id } }

    delete "/session", params: { session: {} }

    assert_redirected_to "/todos"
    assert_nil session[:current_user_id]
  end

  test "users page renders typed user management" do
    Models::User.create!(name: "owner", email: "owner-users@example.test", role: "admin")

    get "/users"

    assert_response :success
    assert_includes @response.body, "Typed users, ordinary Rails output."
    assert_includes @response.body, "owner-users@example.test"
    assert_includes @response.body, "Back to todo board"
  end

  test "chat message create permits haxe-authored params and redirects" do
    user = Models::User.create!(name: "room owner", email: "room-create@example.test", role: "maintainer")

    assert_broadcasts("todoapp:chat", 1) do
      assert_difference "Models::ChatMessage.count", 1 do
        post "/chat_messages", params: { chat_message: { body: "from typed room", user_id: user.id, ignored: "nope" } }
      end
    end

    assert_redirected_to "/todos"
    message = Models::ChatMessage.order(:id).last
    assert_equal "from typed room", message.body
    assert_equal user, message.user
  end

  test "chat message index returns a turbo stream room snapshot" do
    user = Models::User.create!(name: "room sync owner", email: "room-sync@example.test", role: "maintainer")
    Models::ChatMessage.create!(body: "late subscriber snapshot", user: user)

    get "/chat_messages", headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes @response.media_type, "text/vnd.turbo-stream.html"
    assert_includes @response.body, '<turbo-stream action="replace" target="railshx-chat-panel">'
    assert_includes @response.body, "late subscriber snapshot"
  end
end
