# frozen_string_literal: true

module Admin
  # File type and size are validated by the import model (active_storage_validations).
  class CreateImportContract < ApplicationContract
    params do
      required(:spreadsheet).filled

      before(:value_coercer) do |result|
        result.to_h.compact_blank!
      end
    end
  end
end
