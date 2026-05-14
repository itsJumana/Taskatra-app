Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ]
  resource :registration, only: %i[ new create ]
  resources :passwords, param: :token, only: %i[ new create edit update ]

  get "home" => "pages#home", as: :home_page

  resources :projects, param: :slug do
    resources :tasks, shallow: true
    resources :memberships, only: %i[ index create destroy ], shallow: true
  end

  resources :tasks, only: [] do
    resource :status, only: %i[ update ]
    resource :assignment, only: %i[ update ]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "projects#index"
end
