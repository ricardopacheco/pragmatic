# frozen_string_literal: true

require "test_helper"

module Guest
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    setup { @user = create(:user, password: "password") }

    test "new renders the sign in form" do
      get new_session_path

      assert_response :success
    end

    test "new redirects a signed-in user to their profile" do
      sign_in_as(@user)

      get new_session_path

      assert_redirected_to profile_path
    end

    test "new redirects a signed-in admin to the dashboard" do
      sign_in_as(create(:user, :admin))

      get new_session_path

      assert_redirected_to admin_dashboard_path
    end

    test "create sends an admin to the dashboard" do
      admin = create(:user, :admin, password: "password")

      post session_path, params: {session: {email: admin.email, password: "password"}}

      assert_redirected_to admin_dashboard_path
    end

    test "create signs the user in" do
      post session_path, params: {session: {email: @user.email, password: "password"}}

      assert_redirected_to profile_path
      assert cookies[:session_id].present?
      assert_equal I18n.t("guest.sessions.create.success"), flash[:notice]
      assert_equal 1, @user.sessions.count
    end

    test "create rejects invalid credentials" do
      post session_path, params: {session: {email: @user.email, password: "wrong-password"}}

      assert_response :unprocessable_entity
      assert_predicate cookies[:session_id], :blank?
      assert_equal 0, @user.sessions.count
    end

    test "create rejects a blank email" do
      post session_path, params: {session: {email: "", password: "password"}}

      assert_response :unprocessable_entity
    end

    test "create enqueues the sessions broadcast job" do
      assert_enqueued_with(job: Sessions::CreateSessionBroadcastJob, queue: "broadcast") do
        post session_path, params: {session: {email: @user.email, password: "password"}}
      end
    end

    # The limiter counts in Rails.cache, which is a null store here: increment always
    # returns nil and the limit can never be reached. Stubbing it is what puts the
    # request past the threshold.
    test "create redirects with an alert once the rate limit is reached" do
      Rails.cache.stubs(:increment).returns(11)

      post session_path, params: {session: {email: @user.email, password: "password"}}

      assert_redirected_to new_session_path
      assert_equal I18n.t("guest.sessions.create.rate_limited"), flash[:alert]
      assert_equal 0, @user.sessions.count
    end

    test "destroy signs the user out" do
      post session_path, params: {session: {email: @user.email, password: "password"}}

      delete session_path

      assert_redirected_to new_session_path
      assert_equal I18n.t("guest.sessions.destroy.success"), flash[:notice]
      assert_equal 0, @user.sessions.count
    end

    test "destroy requires an authenticated user" do
      delete session_path

      assert_redirected_to new_session_path
    end
  end
end
