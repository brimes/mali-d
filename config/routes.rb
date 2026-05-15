Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]

  get "up" => "rails/health#show", as: :rails_health_check

  # Área admin master (vive em subdomínios reservados, p.ex. app.lvh.me)
  namespace :admin do
    resources :companies
    root "dashboard#index"
  end

  # Painel da empresa (subdomínio = tenant)
  resource :dashboard, only: [:show], controller: "dashboard"

  root "home#index"
end
