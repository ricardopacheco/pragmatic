# frozen_string_literal: true

require "test_helper"

class AccountMailerTest < ActionMailer::TestCase
  test "the email is addressed to the person who was removed" do
    mail = deleted_email

    assert_equal ["marina@example.com"], mail.to
    assert_equal I18n.t("account_mailer.deleted.subject"), mail.subject
  end

  test "the email greets the person by name in both parts" do
    mail = deleted_email
    greeting = I18n.t("account_mailer.deleted.greeting", name: "Marina Prado")

    assert_includes mail.html_part.decoded, greeting
    assert_includes mail.text_part.decoded, greeting
  end

  test "the email is written in the current locale" do
    mail = deleted_email(locale: :pt)

    assert_equal I18n.t("account_mailer.deleted.subject", locale: :pt), mail.subject
    assert_includes mail.html_part.decoded, I18n.t("account_mailer.deleted.explanation", locale: :pt)
  end

  test "the layout carries the locale in the lang attribute" do
    assert_includes deleted_email(locale: :pt).html_part.decoded, '<html lang="pt">'
  end

  private

  def deleted_email(locale: I18n.locale)
    I18n.with_locale(locale) do
      AccountMailer.deleted(full_name: "Marina Prado", email: "marina@example.com").message
    end
  end
end
