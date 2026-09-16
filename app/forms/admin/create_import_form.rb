# frozen_string_literal: true

module Admin
  class CreateImportForm < ApplicationForm
    attr_reader :import

    attribute :spreadsheet

    def self.model_name
      ActiveModel::Name.new(self, nil, "Import")
    end

    def submit(admin_id)
      submit_with(Admin::CreateImportOperation, admin_id, attributes) { |import| @import = import }
    end
  end
end
