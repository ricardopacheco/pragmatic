# frozen_string_literal: true

require "test_helper"

module Guest
  class RegistrationsControllerTest < ActionDispatch::IntegrationTest
    test "new renders the registration form" do
      get new_registration_path

      assert_response :success
    end

    test "new redirects a signed-in user to their dashboard" do
      sign_in_as(create(:user, :admin))

      get new_registration_path

      assert_redirected_to admin_dashboard_path
    end

    test "create registers the visitor as a regular user and signs them in" do
      assert_difference -> { User.count }, 1 do
        post registration_path, params: {user: valid_attributes}
      end

      assert_redirected_to profile_path
      assert_equal I18n.t("guest.registrations.create.success"), flash[:notice]
      assert cookies[:session_id].present?
      assert_predicate User.last, :profile?
    end

    test "create rejects invalid data and renders the form again" do
      assert_no_difference -> { User.count } do
        post registration_path, params: {user: valid_attributes.merge(email: "invalid_email")}
      end

      assert_response :unprocessable_entity
    end

    test "create rejects an email that is already taken" do
      create(:user, email: "taken@example.com")

      assert_no_difference -> { User.count } do
        post registration_path, params: {user: valid_attributes.merge(email: "taken@example.com")}
      end

      assert_response :unprocessable_entity
    end

    test "create redirects with an alert once the rate limit is reached" do
      Rails.cache.stubs(:increment).returns(11)

      assert_no_difference -> { User.count } do
        post registration_path, params: {user: valid_attributes}
      end

      assert_redirected_to new_registration_path
      assert_equal I18n.t("guest.registrations.create.rate_limited"), flash[:alert]
    end

    private

    def valid_attributes
      {
        full_name: "Jane Cooper",
        email: "jane@example.com",
        password: "password",
        password_confirmation: "password"
      }
    end
  end
end
