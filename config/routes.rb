Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  #
  get "/", to: "pages#index"

  scope "(:lang)", lang: /ja|en/ do
    root "langs#show"
    get "legal", to: "legal#index"
    get "wiki/:title.md", to: "pages#markdown"
    get "wiki/:title", to: "pages#show"
    post "search", to: "pages#search", as: :search_page
    post "wiki/:id", to: "pages#update", as: :update_page
  end

  mount Clapton::Engine => "/clapton"
end
