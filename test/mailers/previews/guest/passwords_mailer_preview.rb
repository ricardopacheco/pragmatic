# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/guest/passwords_mailer
module Guest
  class PasswordsMailerPreview < ActionMailer::Preview
    # Preview this email at http://localhost:3000/rails/mailers/guest/passwords_mailer/reset
    def reset
      Guest::PasswordsMailer.reset(User.first)
    end
  end
end
