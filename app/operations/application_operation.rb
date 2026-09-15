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

  def create_user_on_database(attributes)
    user = User.new(attributes)

    return Success(user) if user.save

    Failure(user.errors.to_hash)
  end

  def update_user_on_database(user, attributes)
    return Success(user) if user.update(attributes)

    Failure(user.errors.to_hash)
  end

  def find_user(id)
    user = User.find_by(id:)

    return Failure(base: I18n.t("#{I18N_SCOPE}.user_not_found")) if user.blank?

    Success(user)
  end
end
