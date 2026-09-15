# frozen_string_literal: true

scope module: :profile do
  resource :profile, only: %i[show edit update destroy] do
    resource :password, only: :update, controller: "passwords"
  end
end
