class OmniAuthErrorHandler
  CALLBACK_PATH = "/auth/spotify/callback"

  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue OAuth2::Error => e
    Rails.logger.error "omniauth oauth2 error on callback: #{e.class}: #{e.message}"
    raise unless env["PATH_INFO"] == CALLBACK_PATH
    frontend = ENV.fetch("FRONTEND_ORIGIN", "http://localhost:5173")
    [302, { "Location" => "#{frontend}/auth/error", "Content-Type" => "text/html" }, []]
  end
end
