class AddReleaseDateToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :release_date, :string
  end
end
