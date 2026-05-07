class CreateSongs < ActiveRecord::Migration[8.1]
  def change
    create_table :songs do |t|
      t.string :spotify_track_id, null: false
      t.string :title, null: false
      t.string :artist_name, null: false
      t.string :album_name
      t.string :album_art_url

      t.timestamps
    end
    add_index :songs, :spotify_track_id, unique: true
  end
end
