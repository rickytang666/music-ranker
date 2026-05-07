class CreateRankings < ActiveRecord::Migration[8.1]
  def change
    create_table :rankings do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false

      t.timestamps
    end
  end
end
