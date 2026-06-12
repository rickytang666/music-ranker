class RemoveSpotifyLastExportUrisFromRankings < ActiveRecord::Migration[8.1]
  def change
    remove_column :rankings, :spotify_last_export_uris, :text
  end
end
