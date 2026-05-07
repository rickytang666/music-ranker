class SpotifyTokenRefreshService
  SPOTIFY_TOKEN_URL = "https://accounts.spotify.com/api/token"

  def self.call(user)
    new(user).call
  end

  def initialize(user)
    @user = user
  end

  def call
    return unless @user.token_expired?

    response = request_new_token
    update_user_tokens(response)
  end

  private

  def request_new_token
    uri = URI(SPOTIFY_TOKEN_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "Basic #{encoded_credentials}"
    req["Content-Type"] = "application/x-www-form-urlencoded"
    req.body = URI.encode_www_form(grant_type: "refresh_token", refresh_token: @user.refresh_token)

    res = http.request(req)
    raise "spotify token refresh failed: #{res.code}" unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  end

  def update_user_tokens(data)
    @user.update!(
      access_token: data["access_token"],
      token_expires_at: Time.current + data["expires_in"].to_i.seconds,
      refresh_token: data.fetch("refresh_token", @user.refresh_token)
    )
  end

  def encoded_credentials
    Base64.strict_encode64("#{ENV.fetch("SPOTIFY_CLIENT_ID")}:#{ENV.fetch("SPOTIFY_CLIENT_SECRET")}")
  end
end
