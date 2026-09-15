# frozen_string_literal: true

class AccountMailerPreview < ActionMailer::Preview
  def deleted
    user = User.first

    AccountMailer.deleted(full_name: user.full_name, email: user.email)
  end
end
