require "test_helper"

class ChatMessageTest < ActiveSupport::TestCase
  test "validates required body and belongs to a user" do
    user = Models::User.create!(name: "room owner", email: "room-owner@example.test", role: "admin")
    message = Models::ChatMessage.new(user: user)

    assert_not message.valid?
    assert_includes message.errors[:body], "can't be blank"
    message.body = "typed chat works"
    assert message.valid?
    assert_equal user, message.user
  end

  test "latest returns newest typed messages with users loaded" do
    user = Models::User.create!(name: "room owner", email: "room-latest@example.test", role: "admin")
    first = Models::ChatMessage.create!(body: "first", user: user)
    second = Models::ChatMessage.create!(body: "second", user: user)

    assert_equal [second.body, first.body], Models::ChatMessage.latest.pluck(:body)
  end
end
