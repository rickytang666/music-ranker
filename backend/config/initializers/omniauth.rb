OmniAuth.config.allowed_request_methods = [ :get, :post ]
OmniAuth.config.silence_get_warning = true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :spotify,
    ENV.fetch("SPOTIFY_CLIENT_ID", nil),
    ENV.fetch("SPOTIFY_CLIENT_SECRET", nil),
    scope: "user-read-private user-read-email",
    callback_url: ENV.fetch("SPOTIFY_REDIRECT_URI", "http://127.0.0.1:3000/auth/spotify/callback")
end
