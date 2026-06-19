require "test_helper"

class TodosControllerTest < ActionDispatch::IntegrationTest
  test "index renders the polished RailsHx todo page with ordered open work" do
    user = create_user!(name: "owner", email: "owner@example.test", role: "admin")
    create_user!(name: "member", email: "member@example.test", role: "member")
    Models::Todo.create!(title: "zed open task", is_completed: false, user: user)
    Models::Todo.create!(title: "alpha open task", is_completed: false, user: user)
    Models::Todo.create!(title: "completed hidden task", is_completed: true, user: user)
    Models::ChatMessage.create!(body: "typed chat note", user: user)

    get "/todos"

    assert_response :success
    assert_includes @response.body, "Typed Rails, polished Ruby."
    assert_includes @response.body, "RailsHx sample"
    assert_includes @response.body, "DeviseHx auth layer"
    assert_includes @response.body, "Guest gate"
    assert_includes @response.body, "Open Devise login"
    assert_includes @response.body, "Continue as guest"
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
    user = create_user!(name: "owner", email: "owner-create@example.test", role: "admin")
    sign_in user

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
    user = create_user!(name: "owner", email: "owner-invalid@example.test", role: "admin")
    sign_in user

    assert_no_difference "Models::Todo.count" do
      post "/todos", params: { todo: { title: "", notes: "missing title", user_id: user.id } }
    end

    assert_redirected_to "/todos"
  end

  test "guest sign in uses Devise and reaches protected RailsHx pages" do
    create_user!(name: "Guest Workspace", email: "guest@example.test", role: "guest")

    post "/guest"

    assert_redirected_to "/todos"
    get "/users"
    assert_response :success
    assert_includes @response.body, "Guest Workspace"
  end

  test "devise sign out returns guests to the public board" do
    user = create_user!(name: "session owner", email: "session-clear@example.test", role: "maintainer")
    sign_in user

    delete "/users/sign_out"

    assert_redirected_to "/"
    get "/users"
    assert_redirected_to "/users/sign_in"
  end

  test "users page renders typed user management" do
    user = create_user!(name: "owner", email: "owner-users@example.test", role: "admin")
    sign_in user

    get "/users"

    assert_response :success
    assert_includes @response.body, "Typed users, ordinary Rails output."
    assert_includes @response.body, "owner-users@example.test"
    assert_includes @response.body, "Back to todo board"
  end

  test "chat message create permits haxe-authored params and redirects" do
    user = create_user!(name: "room owner", email: "room-create@example.test", role: "maintainer")
    sign_in user

    assert_difference "Models::ChatMessage.count", 1 do
      post "/chat_messages", params: { chat_message: { body: "from typed room", user_id: user.id, ignored: "nope" } }
    end

    assert_redirected_to "/todos"
    message = Models::ChatMessage.order(:id).last
    assert_equal "from typed room", message.body
    assert_equal user, message.user
  end

  test "chat message create broadcasts through Turbo Streams for turbo clients" do
    user = create_user!(name: "room stream owner", email: "room-stream@example.test", role: "maintainer")
    sign_in user

    assert_difference "Models::ChatMessage.count", 1 do
      post "/chat_messages",
        params: { chat_message: { body: "streamed row", user_id: user.id } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :no_content
  end
end
