require "devise"

Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Devise (API v1)
  devise_for :users,
    defaults: { format: :json },
    path: "api/v1",
    path_names: {
      sign_in: "auth/login",
      sign_out: "auth/logout",
      registration: "auth/signup"
    },
    controllers: {
      sessions: "users/sessions",
      registrations: "users/registrations"
    }

  # API v1
  namespace :api do
    namespace :v1 do
      # テスト用
      get "hello", to: "hello#index"
      post "hello", to: "hello#create"

      # ユーザ関連
      get "me", to: "users#me"
      resources :users
    end
  end
end
