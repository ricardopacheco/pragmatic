# frozen_string_literal: true

require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
  end

  test "an unauthenticated request goes to the sign in and comes back after it" do
    get edit_profile_path

    assert_redirected_to new_session_path

    post session_path, params: {session: {email: @user.email, password: "password"}}

    assert_redirected_to edit_profile_url
  end

  test "signing out enqueues the sessions broadcast job" do
    post session_path, params: {session: {email: @user.email, password: "password"}}

    assert_enqueued_with(job: Sessions::DeleteSessionBroadcastJob, args: [@user.id]) do
      delete session_path
    end
  end
end
