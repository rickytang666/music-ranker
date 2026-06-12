class AddSpotifySyncToRankings < ActiveRecord::Migration[8.1]
  def change
    add_column :rankings, :spotify_sync_count, :integer
    add_column :rankings, :spotify_sync_error, :boolean, default: false, null: false
  end
end
