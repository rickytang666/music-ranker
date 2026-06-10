class AddSpotifyExportToRankings < ActiveRecord::Migration[8.1]
  def change
    add_column :rankings, :spotify_playlist_id, :string
    add_column :rankings, :spotify_last_export_count, :integer
  end
end
