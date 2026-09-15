# frozen_string_literal: true

module Profile
  class UpdateProfileOperation < ApplicationOperation
    def call(user_id, attributes)
      user = yield find_user(user_id)
      validated = yield validate_contract(Profile::UpdateProfileContract, attributes, user:)

      ActiveRecord::Base.transaction do
        yield update_user_on_database(user, profile_attributes(validated))
        yield remove_avatar_image(user, validated)
      end

      Success(user)
    end

    private

    def profile_attributes(validated)
      validated.to_h.except(:remove_avatar_image)
    end
  end
end
