# frozen_string_literal: true

require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    # Sessions are created straight from the user, like SessionTestHelper does: a
    # Session factory would exist only for this test.
    test "connects with the user of the session cookie" do
      user = create(:user)
      cookies.signed[:session_id] = user.sessions.create!.id

      connect

      assert_equal user, connection.current_user
    end

    test "rejects a connection without a session cookie" do
      assert_reject_connection { connect }
    end

    test "rejects a connection whose session no longer exists" do
      cookies.signed[:session_id] = 0

      assert_reject_connection { connect }
    end
  end
end
