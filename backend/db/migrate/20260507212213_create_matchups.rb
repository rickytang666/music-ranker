class CreateMatchups < ActiveRecord::Migration[8.1]
  def change
    create_table :matchups do |t|
      t.references :ranking, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :song_a_id, null: false
      t.bigint :song_b_id, null: false
      t.bigint :winner_id, null: false
      t.datetime :played_at, null: false

      t.timestamps
    end
    add_foreign_key :matchups, :songs, column: :song_a_id
    add_foreign_key :matchups, :songs, column: :song_b_id
    add_foreign_key :matchups, :songs, column: :winner_id
    add_index :matchups, [ :ranking_id, :played_at ]
  end
end
