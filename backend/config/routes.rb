Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "rails/health#show"

  get "/auth/spotify/callback", to: "auth#callback"
  get "/auth/failure", to: "auth#failure"

  namespace :api do
    namespace :v1 do
      get "auth/me", to: "auth#me"
      delete "auth/logout", to: "auth#logout"
    end
  end
end
