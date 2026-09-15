# frozen_string_literal: true

# Public area: the URLs stay at the root, the controllers live in the Guest module.
scope module: :guest do
  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]
  resources :passwords, param: :token, only: %i[new create edit update]
end
