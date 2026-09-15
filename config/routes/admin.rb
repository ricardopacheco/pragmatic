# frozen_string_literal: true

namespace :admin do
  resource :dashboard, only: :show

  resources :users, except: :show do
    resource :role, only: :update, controller: "roles"
  end

  resources :imports, only: %i[index show create]
end
