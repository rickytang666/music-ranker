class SpotifyClient
  BASE_URL = "https://api.spotify.com/v1"

  class RateLimitError < StandardError; end
  class ForbiddenError < StandardError; end
  class NotFoundError < StandardError; end
  class ServiceUnavailableError < StandardError; end

def initialize(user)
    SpotifyTokenRefreshService.call(user)
    user.reload
    @token = user.access_token
    @user  = user
  end

  def search(query, type:, limit: 10)
    get("/search", { q: query, type: type, limit: limit })
  end

  def artist_albums(artist_id, offset: 0, limit: 50)
    get("/artists/#{artist_id}/albums", { offset: offset, limit: limit, include_groups: "album,single" })
  end

  def album_tracks(album_id, offset: 0)
    get("/albums/#{album_id}/tracks", { offset: offset, limit: 50, market: user_market })
  end

  def track(id)
    get("/tracks/#{id}")
  end

  def create_playlist(name, public: false)
    post("/me/playlists", { name: name, public: public, description: "exported from music ranker" })
  end

  def replace_playlist_tracks(playlist_id, uris)
    put("/playlists/#{playlist_id}/items", { uris: uris })
  end

  def add_tracks_to_playlist(playlist_id, uris)
    post("/playlists/#{playlist_id}/items", { uris: uris })
  end

def update_playlist(playlist_id, name:)
    put("/playlists/#{playlist_id}", { name: name })
  end

  private

  def user_market
    @user_market ||= begin
      if @user.spotify_market.present?
        @user.spotify_market
      else
        market = get("/me")["country"]
        @user.update_column(:spotify_market, market)
        market
      end
    end
  end

  def check_response!(res)
    case res.code
    when "429" then raise RateLimitError, "spotify rate limit — try again in #{res["Retry-After"] || "a moment"}"
    when "403" then raise ForbiddenError, "spotify api error 403: #{res.body}"
    when "404" then raise NotFoundError, "spotify api error 404: #{res.body}"
    when "502", "503" then raise ServiceUnavailableError, "spotify api error #{res.code}: #{res.body}"
    end
    raise "spotify api error #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPNoContent)
  end

  def build_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 10
    http
  end

  def post(path, body = {})
    request(Net::HTTP::Post, path, body)
  end

  def put(path, body = {})
    request(Net::HTTP::Put, path, body)
  end

  def get(path, params = {})
    uri = URI("#{BASE_URL}#{path}")
    if params.any?
      uri.query = params.map { |k, v|
        "#{k}=#{URI.encode_www_form_component(v.to_s).gsub('%2C', ',')}"
      }.join("&")
    end

    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{@token}"

    res = build_http(uri).request(req)
    check_response!(res)
    JSON.parse(res.body)
  end

  def request(klass, path, body = {})
    uri = URI("#{BASE_URL}#{path}")
    req = klass.new(uri)
    req["Authorization"] = "Bearer #{@token}"
    req["Content-Type"] = "application/json"
    req.body = body.to_json

    res = build_http(uri).request(req)
    check_response!(res)
    return nil if res.is_a?(Net::HTTPNoContent) || res.body.nil? || res.body.empty?

    JSON.parse(res.body)
  end
end
