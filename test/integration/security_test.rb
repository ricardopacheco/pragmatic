# frozen_string_literal: true

require "test_helper"

# The traditional vectors, each against the pages that render or query what a
# user typed. Escaping, binding and the token are Rails defaults; this pins them.
class SecurityTest < ActionDispatch::IntegrationTest
  PAYLOAD = "<script>alert(1)</script>"

  setup { @admin = create(:user, :admin) }

  test "a name with markup is escaped in the users list and the dashboard" do
    create(:user, full_name: PAYLOAD)
    sign_in_as(@admin)

    [admin_users_path, admin_dashboard_path].each do |path|
      get path

      assert_response :success
      assert_escaped
    end
  end

  test "a name with markup is escaped in the profile" do
    sign_in_as(create(:user, full_name: PAYLOAD))

    get profile_path

    assert_response :success
    assert_escaped
  end

  test "the search query is escaped when echoed back" do
    sign_in_as(@admin)

    get admin_users_path(query: %(">#{PAYLOAD}))

    assert_response :success
    assert_escaped
  end

  test "a search with SQL is bound as a plain string" do
    create(:user)
    sign_in_as(@admin)

    get admin_users_path(query: "' OR 1=1 --")

    assert_response :success
    assert_select "h2", I18n.t("admin.users.empty.heading")
  end

  test "a role filter with SQL is ignored" do
    create(:user)
    sign_in_as(@admin)

    get admin_users_path(role: "admin' --")

    assert_response :success
    assert_select "tr[id^=user_]", 2
  end

  test "signing in without the authenticity token is rejected" do
    with_forgery_protection do
      assert_no_difference "Session.count" do
        post session_path, params: {session: {email: @admin.email, password: "password"}}
      end

      assert_response :unprocessable_content
    end
  end

  test "changing a role without the authenticity token is rejected" do
    user = create(:user)
    sign_in_as(@admin)

    with_forgery_protection do
      patch admin_user_role_path(user), params: {user: {role: "admin"}}

      assert_response :unprocessable_content
      assert_predicate user.reload, :profile?
    end
  end

  private

  def assert_escaped
    assert_includes response.body, ERB::Util.html_escape(PAYLOAD)
    assert_not_includes response.body, PAYLOAD
  end

  # Off in the test environment so the other tests need no token; each worker is
  # its own process, so flipping it here reaches no other test.
  def with_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = false
  end
end
