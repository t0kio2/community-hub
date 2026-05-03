require "devise"


Rails.application.routes.draw do

  # API (JWT, user_accounts)
  scope :api do
    scope :v1 do
      devise_for :user_accounts,
        defaults: { format: :json },
        path: 'auth', # /api/v1/auth
        controllers: {
          sessions: 'api/v1/auth/sessions',
          registrations: 'api/v1/auth/registrations'
        }

      # トークンリフレッシュ
      post   'auth/refresh', to: 'api/v1/auth/refresh_tokens#create'
      delete 'auth/refresh', to: 'api/v1/auth/refresh_tokens#destroy'

      get "public/listings", to: "api/v1/public/listings#index"
      get "public/listings/:id", to: "api/v1/public/listings#show"

      get "user/favorites", to: "api/v1/user/favorites#index"
      post "user/favorites", to: "api/v1/user/favorites#create"
      delete "user/favorites/:id", to: "api/v1/user/favorites#destroy"
    end
  end

  # MVC (DBセッション)
  devise_for :tenant_accounts,
             path: 'tenant/auth',
             controllers: { sessions: 'tenant/sessions' },
             defaults: { format: :html },
             sign_out_via: [:post, :delete]
  devise_for :admin_accounts,
             path: 'admin/auth',
             controllers: { sessions: 'admin/sessions' },
             defaults: { format: :html },
             sign_out_via: [:post, :delete]

  namespace :admin do
    root to: 'home#index'
    resources :tenant_accounts, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  end

  namespace :tenant do
    root to: 'home#index'
    resource :organization, only: [:edit, :update]
    resources :listings, only: [:index, :show, :new, :create, :edit, :update]
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
