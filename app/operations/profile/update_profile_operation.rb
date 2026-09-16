# frozen_string_literal: true

module Profile
  class UpdateProfileOperation < ApplicationOperation
    def call(user_id, attributes)
      user = yield find_user(user_id)
      validated = yield validate_contract(Profile::UpdateProfileContract, attributes, user:)

      ActiveRecord::Base.transaction do
        yield update_user_on_database(user, profile_attributes(validated))
        yield remove_avatar_image(user, validated)
        yield send_update_profile_broadcast(user.id)
      end

      Success(user)
    end

    private

    def profile_attributes(validated)
      validated.to_h.except(:remove_avatar_image)
    end

    def send_update_profile_broadcast(user_id)
      Success(Profile::UpdateProfileBroadcastJob.perform_later(user_id, request_id: Turbo.current_request_id))
    end
  end
end
