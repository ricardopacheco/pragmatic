# frozen_string_literal: true

module Profile
  class UpdateProfileContract < ApplicationContract
    option :user_repo, default: proc { ::User }

    params do
      required(:full_name).filled(:string)
      required(:email).filled(:string)
      optional(:avatar_image)
      optional(:remove_avatar_image).filled(:bool)

      before(:value_coercer) do |result|
        result.to_h.compact_blank!
      end
    end

    rule(:full_name).validate(:full_name_format)
    rule(:email).validate(:email_format)

    rule(:email).validate(:email_not_taken)
  end
end
