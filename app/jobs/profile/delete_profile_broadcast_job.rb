# frozen_string_literal: true

module Profile
  class DeleteProfileBroadcastJob < ApplicationJob
    queue_as :broadcast

    def perform(_user_id, request_id: nil)
      broadcast_dashboard
      broadcast_users_list(request_id)
    end
  end
end
