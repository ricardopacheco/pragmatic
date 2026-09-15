# frozen_string_literal: true

module Guest
  class PasswordsMailer < ApplicationMailer
    def reset(user)
      @user = user

      mail subject: t(".subject"), to: user.email
    end
  end
end
