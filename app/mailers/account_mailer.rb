# frozen_string_literal: true

class AccountMailer < ApplicationMailer
  def deleted(full_name:, email:)
    @full_name = full_name

    mail subject: t(".subject"), to: email
  end
end
