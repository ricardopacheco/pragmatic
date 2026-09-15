# frozen_string_literal: true

module Profile
  class UserDecorator < Burgundy::Item
    include UserPresentation

    attributes :id, :full_name, :email

    def member_since
      l(item.created_at.to_date, format: :long)
    end
  end
end
