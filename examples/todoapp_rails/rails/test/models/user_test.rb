require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "validates required name" do
    user = Models::User.new

    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end
end
