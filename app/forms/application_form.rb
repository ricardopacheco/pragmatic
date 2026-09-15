# frozen_string_literal: true

class ApplicationForm
  include ActiveModel::API
  include ActiveModel::Attributes

  def persisted?
    false
  end

  private

  def submit_with(operation, *args)
    operation.call(*args) do |result|
      result.success do |value|
        yield(value) if block_given?

        true
      end

      result.failure do |failure|
        copy_error_messages(failure.to_h)

        false
      end
    end
  end

  def copy_error_messages(hash)
    hash.each { |key, value| errors.add(key || :base, Array(value).join(", ")) }
  end
end
