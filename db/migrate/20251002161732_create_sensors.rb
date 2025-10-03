class CreateSensors < ActiveRecord::Migration[8.0]
  def change
    create_table :sensors do |t|
      t.string :name
      t.string :brand
      t.string :model
      t.string :serial_number
      t.references :access_controller, null: false, foreign_key: true
      t.references :entry_way, null: false, foreign_key: true
      t.string :last_known_state
      t.datetime :last_state_update

      t.timestamps
    end
  end
end
