# frozen_string_literal: true

class Session < ApplicationRecord
  belongs_to :user

  encrypts :ip_address, :user_agent
end
