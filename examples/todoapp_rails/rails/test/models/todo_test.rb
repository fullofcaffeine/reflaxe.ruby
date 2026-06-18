require "test_helper"

class TodoTest < ActiveSupport::TestCase
  test "incomplete returns incomplete todos" do
    user = Models::User.create!(name: "owner", email: "owner@example.test", role: "admin")
    Models::Todo.create!(title: "ship ruby", is_completed: false, user: user)
    Models::Todo.create!(title: "done", is_completed: true, user: user)

    assert_equal ["ship ruby"], Models::Todo.incomplete.map(&:title)
  end

  test "validates required title" do
    user = Models::User.create!(name: "owner", email: "owner-title@example.test", role: "admin")
    todo = Models::Todo.new(user: user, notes: "missing title", is_completed: false)

    assert_not todo.valid?
    assert_includes todo.errors[:title], "can't be blank"
  end

  test "belongs to a user and user has many todos" do
    user = Models::User.create!(name: "owner", email: "owner-association@example.test", role: "admin")
    todo = Models::Todo.create!(title: "owned task", user: user)

    assert_equal user, todo.user
    assert_includes user.todos, todo
  end
end
