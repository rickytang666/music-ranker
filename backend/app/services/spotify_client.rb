class SpotifyClient
  BASE_URL = "https://api.spotify.com/v1"

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
    get("/artists/#{artist_id}/albums", { offset: offset, limit: limit, include_groups: "album,single", market: user_market })
  end

  def album_tracks(album_id, offset: 0)
    get("/albums/#{album_id}/tracks", { offset: offset, limit: 50, market: user_market })
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

  def get(path, params = {}, retries: 2)
    uri = URI("#{BASE_URL}#{path}")
    if params.any?
      uri.query = params.map { |k, v|
        "#{k}=#{URI.encode_www_form_component(v.to_s).gsub('%2C', ',')}"
      }.join("&")
    end

    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{@token}"

    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) { |http| http.request(req) }

    if res.code == "429" && retries > 0
      wait = (res["Retry-After"] || "2").to_i
      sleep(wait)
      return get(path, params, retries: retries - 1)
    end

    raise "spotify api error #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  end
end
