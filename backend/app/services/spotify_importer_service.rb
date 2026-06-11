class SpotifyImporterService
  def initialize(user)
    @client = SpotifyClient.new(user)
  end

  def search_artists(query)
    data = @client.search(query, type: "artist", limit: 5)
    data.dig("artists", "items").map do |a|
      { id: a["id"], name: a["name"], image_url: a.dig("images", 0, "url") }
    end
  end

  def search_albums(query)
    data = @client.search(query, type: "album", limit: 10)
    data.dig("albums", "items").map do |a|
      {
        id: a["id"],
        name: a["name"],
        artist_name: a.dig("artists", 0, "name"),
        image_url: a.dig("images", 0, "url"),
        release_date: a["release_date"]
      }
    end
  end

  def search_tracks(query)
    data = @client.search(query, type: "track", limit: 10)
    tracks = data.dig("tracks", "items").map { |t| serialize_track(t) }
    upsert_songs(tracks)
  end

  def artist_albums(artist_id)
    data = @client.artist_albums(artist_id)
    data["items"].map do |a|
      {
        id: a["id"],
        name: a["name"],
        artist_name: a.dig("artists", 0, "name"),
        image_url: a.dig("images", 0, "url"),
        release_date: a["release_date"]
      }
    end
  end

  def import_artist_tracks(artist_id)
    albums = fetch_all_albums(artist_id)
    tracks = fetch_tracks_for_albums(albums)
    upsert_songs(tracks)
  end

  def import_album_tracks(album_id, album: nil)
    tracks = paginate_spotify { |offset| @client.album_tracks(album_id, offset: offset) }
    upsert_songs(tracks.map { |t| serialize_track(t, album: album) })
  rescue RuntimeError => e
    Rails.logger.warn "album import failed #{album_id}: #{e.message}"
    []
  end

  private

  def paginate_spotify(&fetch)
    items  = []
    offset = 0
    loop do
      data    = fetch.call(offset)
      fetched = data["items"]
      items  += fetched
      break if data["next"].nil? || fetched.empty?
      offset += fetched.length
    end
    items
  end

  def fetch_all_albums(artist_id)
    paginate_spotify { |offset| @client.artist_albums(artist_id, offset: offset, limit: 50) }
  end

  def fetch_tracks_for_albums(albums)
    albums.flat_map do |album|
      tracks = paginate_spotify { |offset| @client.album_tracks(album["id"], offset: offset) }
      tracks.map { |t| serialize_track(t, album: album) }
    rescue RuntimeError => e
      Rails.logger.warn "skipping album #{album["id"]}: #{e.message}"
      []
    end
  end

  def upsert_songs(tracks)
    tracks.map do |t|
      Song.find_or_create_by!(spotify_track_id: t[:spotify_track_id]) do |s|
        s.title = t[:title]
        s.artist_name = t[:artist_name]
        s.album_name = t[:album_name]
        s.album_art_url = t[:album_art_url]
        s.release_date = t[:release_date]
        s.spotify_album_id = t[:spotify_album_id]
      end
    end
  end

  def serialize_track(track, album: nil)
    album ||= track["album"]
    {
      spotify_track_id: track["id"],
      title: track["name"],
      artist_name: track.dig("artists", 0, "name"),
      album_name: album&.dig("name"),
      album_art_url: album&.dig("images", 0, "url"),
      release_date: album&.dig("release_date"),
      spotify_album_id: album&.dig("id")
    }
  end
end
