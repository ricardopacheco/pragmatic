require "test_helper"

module Guest
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    setup { @user = User.take }

    test "new" do
      get new_session_path
      assert_response :success
    end

    test "create with invalid credentials" do
      post session_path, params: {email: @user.email, password: "wrong"}

      assert_redirected_to new_session_path
      assert_nil cookies[:session_id]
    end

    test "destroy" do
      sign_in_as(User.take)

      delete session_path

      assert_redirected_to new_session_path
      assert_empty cookies[:session_id]
    end
  end
end
