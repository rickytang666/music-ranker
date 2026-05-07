class CreateRankingSongs < ActiveRecord::Migration[8.1]
  def change
    create_table :ranking_songs do |t|
      t.references :ranking, null: false, foreign_key: { on_delete: :cascade }
      t.references :song, null: false, foreign_key: { on_delete: :cascade }
      t.float :elo_score, null: false, default: 1000.0
      t.integer :matchup_count, null: false, default: 0

      t.timestamps
    end
    add_index :ranking_songs, [ :ranking_id, :song_id ], unique: true
  end
end
