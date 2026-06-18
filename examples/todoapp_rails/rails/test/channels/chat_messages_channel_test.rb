require "test_helper"
require "action_cable/channel/test_case"

class ChatMessagesChannelTest < ActionCable::Channel::TestCase
  tests Channels::ChatMessagesChannel

  test "subscribes to the typed chat stream" do
    subscribe

    assert subscription.confirmed?
    assert_has_stream "todoapp:chat"
  end

  test "broadcasts typed chat payloads" do
    assert_broadcast_on("todoapp:chat", { "id" => 7, "body" => "typed cable note", "userId" => 42 }) do
      Channels::ChatMessagesChannel.announce(7, "typed cable note", 42)
    end
  end
end
