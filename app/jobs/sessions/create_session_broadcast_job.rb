# frozen_string_literal: true

module Sessions
  class CreateSessionBroadcastJob < ApplicationJob
    queue_as :broadcast

    def perform(user_id)
      broadcast_sessions(user_id)
    end
  end
end
