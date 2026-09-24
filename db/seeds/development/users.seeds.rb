# frozen_string_literal: true

# Up to 100 users for the lists, the dashboard and the search. A few names are picked by
# hand so accents and ç are always there to search for; Faker fills the rest.
after "shared:users" do
  # bcrypt takes almost a second per password: every generated user shares this one.
  password_digest = BCrypt::Password.create("password")

  names = [
    "João Gonçalves", "Conceição Araújo", "Márcia Leão", "Estêvão Ribeiro",
    "Inês Magalhães", "Luís Peçanha", "Açucena Brandão", "Ângela Simões"
  ]
  names += Array.new(100 - names.size) { Faker::Name.name }

  names.each_with_index do |full_name, index|
    email = "#{I18n.transliterate(full_name).parameterize(separator: ".")}.#{index}@pragmatic.dev"

    User.find_or_create_by!(email:) do |user|
      user.full_name = full_name
      user.password_digest = password_digest
      user.role = (index < 5) ? :admin : :profile
      user.created_at = Faker::Config.random.rand(1..180).days.ago
    end
  end
end
