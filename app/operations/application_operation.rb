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
end
