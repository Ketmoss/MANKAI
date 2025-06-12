Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :exchanges, only: [:index, :edit, :update, :show, :destroy]
  resources :owned_mangas do
    resources :exchanges, only: [:new, :create]
  end
  resources :db_mangas, only: [:index, :show] do
    resources :reviews, only: [:create, :new, :show, :destroy]
    resources :owned_mangas
  end

    resources :db_mangas do
      member do
        post 'add_to_collection'
      end
    end

  # Defines the root path route ("/")
  # root "posts#index"
  resources :user_collections do
    resources :owned_mangas
  end
  resources :user_collections

end
