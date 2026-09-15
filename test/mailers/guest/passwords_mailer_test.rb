# frozen_string_literal: true

require "test_helper"

module Guest
  class PasswordsMailerTest < ActionMailer::TestCase
    setup do
      @user = create(:user, full_name: "Marina Prado")
    end

    test "the email is addressed to whoever asked for the reset" do
      mail = PasswordsMailer.reset(@user)

      assert_equal [@user.email], mail.to
      assert_equal I18n.t("guest.passwords_mailer.reset.subject"), mail.subject
    end

    test "the link carries a token that resolves back to the user" do
      mail = PasswordsMailer.reset(@user)

      # The token changes on every call, so what matters is where it leads.
      token = mail.text_part.decoded[%r{/passwords/([^/]+)/edit}, 1]

      assert_equal @user, User.find_by_password_reset_token(token)
    end

    test "both parts greet the user by name" do
      mail = PasswordsMailer.reset(@user)
      greeting = I18n.t("guest.passwords_mailer.reset.greeting", name: @user.full_name)

      assert_includes mail.html_part.decoded, greeting
      assert_includes mail.text_part.decoded, greeting
    end

    test "the email is written in the current locale" do
      # Rendering is lazy: #message forces it while the locale still applies.
      mail = I18n.with_locale(:pt) { PasswordsMailer.reset(@user).message }

      assert_equal I18n.t("guest.passwords_mailer.reset.subject", locale: :pt), mail.subject
      assert_includes mail.html_part.decoded, I18n.t("guest.passwords_mailer.reset.explanation", locale: :pt)
    end
  end
end
