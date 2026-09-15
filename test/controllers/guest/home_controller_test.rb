# frozen_string_literal: true

require "test_helper"

module Guest
  class HomeControllerTest < ActionDispatch::IntegrationTest
    test "renders the landing page for visitors" do
      get root_path

      assert_response :success
    end

    test "redirects a signed-in user to their profile" do
      sign_in_as(create(:user))

      get root_path

      assert_redirected_to profile_path
    end

    test "redirects a signed-in admin to the dashboard" do
      sign_in_as(create(:user, :admin))

      get root_path

      assert_redirected_to admin_dashboard_path
    end
  end
end
