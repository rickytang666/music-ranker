class AddSpotifyLastExportUrisToRankings < ActiveRecord::Migration[8.1]
  def change
    add_column :rankings, :spotify_last_export_uris, :text
  end
end
