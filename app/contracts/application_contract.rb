# frozen_string_literal: true

class ApplicationContract < Dry::Validation::Contract
  config.messages.backend = :i18n
  config.messages.top_namespace = "contracts"

  register_macro(:email_format) do
    next unless key?

    unless Rails.configuration.x.validations.email_format.match?(value)
      key.failure(I18n.t("contracts.errors.custom.macro.email_format"))
    end
  end

  register_macro(:full_name_format) do
    next unless key?

    length = Rails.configuration.x.validations.full_name_length
    unless length.cover?(value.length)
      key.failure(I18n.t("contracts.errors.custom.macro.full_name_format", min: length.min, max: length.max))
    end
  end

  register_macro(:password_format) do
    next unless key?

    length = Rails.configuration.x.validations.password_length
    unless length.cover?(value.length)
      key.failure(I18n.t("contracts.errors.custom.macro.password_format", min: length.min, max: length.max))
    end
  end

  register_macro(:email_not_taken) do |context:|
    next if rule_error?(:email)

    taken = user_repo.where(email: value).where.not(id: context[:user]&.id).exists?
    key.failure(I18n.t("errors.messages.taken")) if taken
  end

  # Use with rule(:password, :password_confirmation).
  register_macro(:password_confirmation) do
    next if rule_error?(:password) || values[:password] == values[:password_confirmation]

    key(:password_confirmation).failure(
      I18n.t("errors.messages.confirmation", attribute: User.human_attribute_name(:password))
    )
  end
end
