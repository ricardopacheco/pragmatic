# frozen_string_literal: true

module Admin
  class UpdateUserRoleContract < ApplicationContract
    params do
      required(:role).filled(:string, included_in?: ::User.roles.keys)

      before(:value_coercer) do |result|
        result.to_h.compact_blank!
      end
    end
  end
end
