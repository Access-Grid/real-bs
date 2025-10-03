class CreateEntryWays < ActiveRecord::Migration[8.0]
  def change
    create_table :entry_ways do |t|
      t.string :name
      t.references :sector, null: false, foreign_key: true
      t.references :access_controller, null: false, foreign_key: true

      t.timestamps
    end
  end
end
