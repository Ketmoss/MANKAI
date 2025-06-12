Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :exchanges, only: [:index, :edit, :update, :show, :destroy] do
    resources :chats, only: [:index, :create]
  end

  resources :owned_mangas do
    resources :exchanges, only: [:new, :create]
  end


  resources :chat, only: :show do
    resources :messages, only: [:create]
  end

  resources :db_mangas, only: [:index, :show] do
    resources :reviews, only: [:create, :new, :show, :destroy]
    resources :owned_mangas
  end
  # Defines the root path route ("/")
  # root "posts#index"
  resources :user_collections do
    # user_collections/1/db_mangas
    # user_collections/1/db_mangas/1/owned_mangas
    # user/collections/1/owned_mangas
    # user/collections/1/owned_mangas/1
    resources :owned_mangas, only: :show

    get "db_mangas", to: "db_mangas#display_db_mangas_list"
    post "db_mangas/:id/owned_mangas", to: "owned_mangas#create", as: "creating_owned_manga"
  end




end
