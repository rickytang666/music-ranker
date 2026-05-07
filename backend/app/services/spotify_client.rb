class SpotifyClient
  BASE_URL = "https://api.spotify.com/v1"

  def initialize(user)
    SpotifyTokenRefreshService.call(user)
    @token = user.reload.access_token
  end

  def search(query, type:, limit: 10)
    get("/search", q: query, type: type, limit: limit)
  end

  def artist_albums(artist_id, limit: 50, offset: 0)
    get("/artists/#{artist_id}/albums", include_groups: "album,single", limit: limit, offset: offset)
  end

  def albums(ids)
    get("/albums", ids: ids.join(","))
  end

  private

  def get(path, params = {})
    uri = URI("#{BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params) if params.any?

    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{@token}"

    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    raise "spotify api error #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  end
end
