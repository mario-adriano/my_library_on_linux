class CreateGames < ActiveRecord::Migration[6.1]
  def change
    create_table :games do |t|
      t.string :name, null: false
      t.string :appid, index: { unique: true }, null: false
      t.integer :tier, default: 7, null: false
      t.integer :trending_tier, default: 7, null: false

      t.timestamps null: false
    end
  end
end
