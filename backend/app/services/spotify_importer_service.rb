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

  def search_tracks(query)
    data = @client.search(query, type: "track", limit: 10)
    data.dig("tracks", "items").map { |t| serialize_track(t) }
  end

  def import_artist_tracks(artist_id)
    album_ids = fetch_all_album_ids(artist_id)
    tracks = fetch_tracks_for_albums(album_ids)
    upsert_songs(tracks)
  end

  private

  def fetch_all_album_ids(artist_id)
    ids = []
    offset = 0
    loop do
      data = @client.artist_albums(artist_id, offset: offset)
      ids += data["items"].map { |a| a["id"] }
      break if data["next"].nil?
      offset += 50
    end
    ids
  end

  def fetch_tracks_for_albums(album_ids)
    album_ids.each_slice(20).flat_map do |batch|
      data = @client.albums(batch)
      data["albums"].flat_map do |album|
        album["tracks"]["items"].map { |t| serialize_track(t, album: album) }
      end
    end
  end

  def upsert_songs(tracks)
    tracks.map do |t|
      Song.find_or_create_by!(spotify_track_id: t[:spotify_track_id]) do |s|
        s.title = t[:title]
        s.artist_name = t[:artist_name]
        s.album_name = t[:album_name]
        s.album_art_url = t[:album_art_url]
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
      album_art_url: album&.dig("images", 0, "url")
    }
  end
end
