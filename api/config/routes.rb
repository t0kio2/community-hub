require "devise"

Rails.application.routes.draw do
  # devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users,
    defaults: { format: :json },
    path: "",
    path_names: {
      sign_in: "api/login",
      sign_out: "api/logout",
      registration: "api/signup"
    },
    controllers: {
      sessions: "users/sessions",
      registrations: "users/registrations"
    }

  # Defines the root path route ("/")
  # root "posts#index"
  namespace :api do
    # テスト用
    get "hello", to: "hello#index"
    post "hello", to: "hello#create"

    # ユーザ関連
    resources :users
  end
end
