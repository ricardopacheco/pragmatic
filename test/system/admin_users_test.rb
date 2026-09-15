# frozen_string_literal: true

require "application_system_test_case"

# The administration area: who gets in, the user CRUD, the role toggle, and the
# search and pagination of the list.
class AdminUsersTest < ApplicationSystemTestCase
  setup do
    @admin = create(:user, :admin, full_name: "Ada Prado")
  end

  test "a regular user has no access to the administration area" do
    sign_in_as create(:user)

    visit admin_users_path

    assert_text I18n.t("admin.unauthorized")
    assert_current_path profile_path
  end

  test "searching narrows the list down to the match" do
    create(:user, full_name: "Bruno Salles")
    create(:user, full_name: "Carla Nunes")

    sign_in_as @admin
    visit admin_users_path

    fill_in I18n.t("admin.users.index.search"), with: "Carla"

    assert_text "Carla Nunes"
    assert_no_text "Bruno Salles"
  end

  test "the search field keeps the focus while the results arrive" do
    create(:user, full_name: "Carla Nunes")

    sign_in_as @admin
    visit admin_users_path

    fill_in I18n.t("admin.users.index.search"), with: "Carla"
    assert_text "Carla Nunes"

    # The field is inside the frame it reloads, so the response replaces it and the
    # focus has to be handed over to the new node.
    assert_equal "query", page.evaluate_script("document.activeElement.id")
  end

  test "a search with no match shows the empty state" do
    sign_in_as @admin
    visit admin_users_path

    fill_in I18n.t("admin.users.index.search"), with: "nobody-by-that-name"

    assert_text I18n.t("admin.users.empty.heading")
  end

  test "the list is paginated" do
    create_list(:user, Admin::UsersController::PER_PAGE)

    sign_in_as @admin
    visit admin_users_path

    assert_selector "#users_list tr", count: Admin::UsersController::PER_PAGE

    click_on I18n.t("admin.users.pagination.next")

    assert_selector "#users_list tr", count: 1
  end

  test "the admin promotes a user with the role toggle" do
    user = create(:user, full_name: "Bruno Salles")

    sign_in_as @admin
    visit admin_users_path

    check I18n.t("admin.users.user.toggle", name: user.full_name)

    assert_text I18n.t("admin.roles.update.success", name: user.full_name)
    assert user.reload.admin?
  end
end
