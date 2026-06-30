require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "validates required name" do
    user = User.new(email: "missing-name@example.test", password: USER_PASSWORD, password_confirmation: USER_PASSWORD)

    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "exposes typed email role and presentation helpers" do
    user = User.new(name: "Owner", email: "owner@example.test", role: "admin", password: USER_PASSWORD, password_confirmation: USER_PASSWORD)

    assert user.valid?
    assert_equal "Admin", user.role_label
    assert_equal "O", user.initials
  end

  test "owns chat messages through typed association metadata" do
    user = create_user!(name: "Owner", email: "owner-chat@example.test", role: "admin")
    message = ChatMessage.create!(body: "typed room note", user: user)

    assert_equal [message], user.chat_messages.to_a
  end
end
