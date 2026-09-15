# frozen_string_literal: true

module Admin
  class UpdateUserRoleForm < ApplicationForm
    attr_reader :user

    attribute :role, :string

    def self.model_name
      ActiveModel::Name.new(self, nil, "User")
    end

    def submit(admin_id, user_id)
      submit_with(Admin::UpdateUserRoleOperation, admin_id, user_id, attributes) { |user| @user = user }
    end
  end
end
