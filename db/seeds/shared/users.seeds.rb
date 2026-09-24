# frozen_string_literal: true

# The accounts every environment starts with. The password is a first step only:
# change it from the profile after the first sign in.
let!(:default_admin) do
  User.find_or_create_by!(email: "admin@pragmatic.dev") do |user|
    user.full_name = "Admin Padrão"
    user.password = "password"
    user.role = :admin
  end
end

let!(:default_user) do
  User.find_or_create_by!(email: "user@pragmatic.dev") do |user|
    user.full_name = "Usuário Padrão"
    user.password = "password"
  end
end
