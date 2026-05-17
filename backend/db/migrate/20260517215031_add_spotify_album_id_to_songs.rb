class AddSpotifyAlbumIdToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :spotify_album_id, :string
  end
end
