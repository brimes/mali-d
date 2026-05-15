Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :admin do
    resources :companies
    root "dashboard#index"
  end

  # Painel da empresa (tenant — subdomínio = company.subdomain)
  resource :dashboard, only: [:show], controller: "dashboard"
  resources :doctors
  resources :employees
  resources :patients do
    member { get :history }
  end
  resources :appointments do
    resource :medical_record, only: [:show, :new, :create, :edit, :update] do
      member { post :sign }
    end
  end

  root "home#index"
end
