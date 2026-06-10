class SpotifyExportService
  BATCH_SIZE = 100

  def self.call(user, ranking, name:, count:, public: false)
    new(user, ranking, name: name, count: count, public: public).call
  end

  def initialize(user, ranking, name:, count:, public: false)
    @user    = user
    @ranking = ranking
    @name    = name
    @count   = count
    @public  = public
  end

  def call
    client = SpotifyClient.new(@user)
    uris   = track_uris

    status = if @ranking.spotify_playlist_id.present?
      overwrite(client, uris)
    else
      create(client, uris)
    end

    @ranking.update!(spotify_last_export_count: @count)

    { status: status, playlist_url: "https://open.spotify.com/playlist/#{@ranking.spotify_playlist_id}" }
  end

  private

  def track_uris
    @ranking.ranking_songs
            .joins(:song)
            .order(elo_score: :desc)
            .limit(@count)
            .pluck("songs.spotify_track_id")
            .map { |id| "spotify:track:#{id}" }
  end

  def create(client, uris)
    playlist = client.create_playlist(@name, public: @public)
    playlist_id = playlist["id"]
    push_tracks(client, playlist_id, uris)
    @ranking.update_columns(spotify_playlist_id: playlist_id, spotify_last_export_uris: uris.to_json)
    :created
  end

  def overwrite(client, uris)
    playlist_id = @ranking.spotify_playlist_id
    stored_uris = JSON.parse(@ranking.spotify_last_export_uris.presence || "[]")
    stored_uris.each_slice(BATCH_SIZE) { |batch| client.delete_playlist_tracks(playlist_id, batch) }
    push_tracks(client, playlist_id, uris)
    client.update_playlist(playlist_id, name: @name)
    @ranking.update_column(:spotify_last_export_uris, uris.to_json)
    :updated
  rescue => e
    raise unless e.message.include?("404") || e.message.include?("403")
    @ranking.update_column(:spotify_playlist_id, nil)
    create(client, uris)
  end

  def push_tracks(client, playlist_id, uris)
    uris.each_slice(BATCH_SIZE) do |batch|
      client.add_tracks_to_playlist(playlist_id, batch)
    end
  end
end
