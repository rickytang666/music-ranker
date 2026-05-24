class AddConfidenceToMatchups < ActiveRecord::Migration[8.1]
  def change
    add_column :matchups, :confidence, :float, default: 1.0
  end
end
