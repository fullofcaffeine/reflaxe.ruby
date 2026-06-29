ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

ActiveRecord::Migration.maintain_test_schema!

class ActiveSupport::TestCase
  USER_PASSWORD = "password123"

  setup do
    Models::ChatMessage.delete_all
    Models::Todo.delete_all
    Models::User.delete_all
  end

  def create_user!(name:, email:, role: "member")
    Models::User.create!(
      name: name,
      email: email,
      role: role,
      password: USER_PASSWORD,
      password_confirmation: USER_PASSWORD
    )
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
