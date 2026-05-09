Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "rails/health#show"

  get "/auth/spotify/callback", to: "auth#callback"
  get "/auth/failure", to: "auth#failure"

  namespace :api do
    namespace :v1 do
      get "auth/me", to: "auth#me"
      delete "auth/logout", to: "auth#logout"

      scope "/spotify" do
        get "search/artists",     to: "spotify#search_artists"
        get "search/tracks",      to: "spotify#search_tracks"
        get "artists/:id/tracks", to: "spotify#artist_tracks"
      end

      resources :rankings, only: [:index, :create, :update, :destroy] do
        resources :songs, only: [:index, :create, :destroy]
        resources :matchups, only: [:create] do
          collection { get :next }
        end
        resource :export, only: [:show]
      end
    end
  end
end
