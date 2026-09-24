# frozen_string_literal: true

require "application_system_test_case"

# The administration area: who gets in, the user CRUD, the role toggle, and the
# search and pagination of the list.
class AdminUsersTest < ApplicationSystemTestCase
  setup do
    @admin = create(:user, :admin)
  end

  test "a regular user has no access to the administration area" do
    sign_in_as create(:user)

    visit admin_users_path

    assert_text I18n.t("admin.unauthorized")
    assert_current_path profile_path
  end

  test "creating a user with an email that is already taken shows an error" do
    taken = create(:user)

    sign_in_as @admin
    visit new_admin_user_path

    fill_in_user(email: taken.email)
    click_on I18n.t("admin.users.new.submit")

    assert_text I18n.t("errors.messages.taken")
  end

  test "creating a user with a mismatched password confirmation shows an error" do
    sign_in_as @admin
    visit new_admin_user_path

    fill_in_user(password_confirmation: "another-password")
    click_on I18n.t("admin.users.new.submit")

    assert_text I18n.t("errors.messages.confirmation", attribute: User.human_attribute_name(:password))
  end

  test "the admin creates a user" do
    sign_in_as @admin
    visit admin_users_path
    click_on I18n.t("admin.users.index.new_user")

    fill_in_user(full_name: "Bruno Salles", email: "bruno@example.com")
    click_on I18n.t("admin.users.new.submit")

    assert_text I18n.t("admin.users.create.success")
    assert_current_path admin_users_path
    assert_text "Bruno Salles"
  end

  test "the admin edits a user" do
    user = create(:user)

    sign_in_as @admin
    visit admin_users_path
    click_on I18n.t("admin.users.user.edit", name: user.full_name)

    fill_in I18n.t("admin.users.form.full_name"), with: "Bruno Salles Neto"
    click_on I18n.t("admin.users.edit.submit")

    assert_text I18n.t("admin.users.update.success")
    assert_text "Bruno Salles Neto"
  end

  test "the admin deletes a user after confirming" do
    user = create(:user)

    sign_in_as @admin
    visit admin_users_path

    click_on I18n.t("admin.users.user.delete", name: user.full_name)
    click_on I18n.t("admin.users.delete_modal.confirm")

    assert_text I18n.t("admin.users.destroy.success")
    assert_no_text user.full_name
    assert_nil User.find_by(id: user.id)
  end

  test "the page stays usable after deleting a user" do
    user = create(:user)

    sign_in_as @admin
    visit admin_users_path

    click_on I18n.t("admin.users.user.delete", name: user.full_name)
    click_on I18n.t("admin.users.delete_modal.confirm")
    assert_text I18n.t("admin.users.destroy.success")

    # Morphing drops the open attribute without calling close(), which used to leave
    # the document blocked by a modal nobody could see.
    assert_equal 0, page.evaluate_script('document.querySelectorAll(":modal").length')

    click_on I18n.t("admin.users.index.new_user")

    assert_current_path new_admin_user_path
  end

  test "searching narrows the list down to the match" do
    other = create(:user)
    match = create(:user)

    sign_in_as @admin
    visit admin_users_path

    fill_in I18n.t("admin.users.index.search"), with: match.full_name

    assert_text match.full_name
    assert_no_text other.full_name
  end

  test "the search field keeps the focus while the results arrive" do
    match = create(:user)

    sign_in_as @admin
    visit admin_users_path

    fill_in I18n.t("admin.users.index.search"), with: match.full_name
    assert_text match.full_name

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
    user = create(:user)

    sign_in_as @admin
    visit admin_users_path

    check I18n.t("admin.users.user.toggle", name: user.full_name)

    assert_text I18n.t("admin.roles.update.success", name: user.full_name)
    assert user.reload.admin?
  end

  private

  def fill_in_user(full_name: "Bruno Salles", email: "bruno@example.com",
    password: "password123", password_confirmation: "password123")
    fill_in I18n.t("admin.users.form.full_name"), with: full_name
    fill_in I18n.t("admin.users.form.email"), with: email
    fill_in I18n.t("admin.users.form.password"), with: password
    fill_in I18n.t("admin.users.form.password_confirmation"), with: password_confirmation
  end
end
