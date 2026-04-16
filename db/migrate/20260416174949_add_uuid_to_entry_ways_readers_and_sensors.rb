class AddUuidToEntryWaysReadersAndSensors < ActiveRecord::Migration[8.0]
  def change
    add_column :entry_ways, :uuid, :string
    add_index :entry_ways, :uuid, unique: true

    add_column :readers, :uuid, :string
    add_index :readers, :uuid, unique: true

    add_column :sensors, :uuid, :string
    add_index :sensors, :uuid, unique: true
  end
end
