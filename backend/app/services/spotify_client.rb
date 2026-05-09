class SpotifyClient
  BASE_URL = "https://api.spotify.com/v1"

  def initialize(user)
    SpotifyTokenRefreshService.call(user)
    @token = user.reload.access_token
  end

  def search(query, type:, limit: 10)
    get("/search", q: query, type: type, limit: limit)
  end

  def artist_albums(artist_id, offset: 0)
    get("/artists/#{artist_id}/albums", offset: offset, include_groups: "album,single", market: user_market)
  end

  def album_tracks(album_id, offset: 0)
    get("/albums/#{album_id}/tracks", offset: offset, limit: 50, market: user_market)
  end

  private

  def user_market
    @user_market ||= get("/me")["country"]
  end

  def get(path, params = {})
    uri = URI("#{BASE_URL}#{path}")
    if params.any?
      uri.query = params.map { |k, v|
        "#{k}=#{URI.encode_www_form_component(v.to_s).gsub('%2C', ',')}"
      }.join("&")
    end

    Rails.logger.info "SPOTIFY REQUEST: #{uri}"
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{@token}"

    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    raise "spotify api error #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  end
end
