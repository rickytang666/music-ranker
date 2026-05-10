class AddIndexesToMatchupsSongs < ActiveRecord::Migration[8.1]
  def change
    add_index :matchups, :song_a_id unless index_exists?(:matchups, :song_a_id)
    add_index :matchups, :song_b_id unless index_exists?(:matchups, :song_b_id)
    add_index :matchups, :winner_id  unless index_exists?(:matchups, :winner_id)
  end
end
