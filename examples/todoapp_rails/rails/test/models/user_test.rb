require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "validates required name" do
    user = Models::User.new(email: "missing-name@example.test")

    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "exposes typed email role and presentation helpers" do
    user = Models::User.new(name: "Owner", email: "owner@example.test", role: "admin")

    assert user.valid?
    assert_equal "Admin", user.role_label
    assert_equal "O", user.initials
  end
end
