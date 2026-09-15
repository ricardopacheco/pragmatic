# frozen_string_literal: true

class ApplicationOperation
  include Dry::Monads[:do, :maybe, :result, :try]

  I18N_SCOPE = "operations.base"

  # Runs the operation. With a block, the result is matched:
  #
  #   Admin::CreateUserOperation.call(admin_id, attributes) do |result|
  #     result.success { |user| ... }
  #     result.failure { |errors| ... }
  #   end
  def self.call(*args, **kwargs, &block)
    service = new.call(*args, **kwargs)

    return service unless block

    Dry::Matcher::ResultMatcher.call(service, &block)
  end

  private

  # Returns the contract result itself, not only its attributes: operations also read
  # what the contract already looked up (result.context[:user]), avoiding a second
  # query or a second bcrypt round.
  def validate_contract(contract_class, attributes, **context)
    result = contract_class.new.call(attributes, **context)

    return Success(result) if result.success?

    Failure(result.errors.to_h)
  end
end
