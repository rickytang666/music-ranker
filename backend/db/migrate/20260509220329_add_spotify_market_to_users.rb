class AddSpotifyMarketToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :spotify_market, :string
  end
end
