class CreateDevicesAndDropOldTables < ActiveRecord::Migration[8.0]
  def change
    create_table :devices do |t|
      # STI discriminator
      t.string :type, null: false

      # Core identity (all device types)
      t.string :name
      t.string :uuid
      t.boolean :enabled, default: true

      # Hierarchy
      t.references :sector, foreign_key: true
      t.references :physical_parent, foreign_key: { to_table: :devices }
      t.references :logical_parent, foreign_key: { to_table: :devices }

      # Hardware info (Controller, CredReader, Sensor)
      t.string :brand
      t.string :model
      t.string :serial_number
      t.boolean :is_virtual

      # State (CredReader, Sensor)
      t.string :last_known_state
      t.datetime :last_state_update

      # Flexible storage
      t.json :metadata
      t.json :public_metadata

      t.timestamps
    end

    add_index :devices, :uuid, unique: true
    add_index :devices, :type

    drop_table :readers
    drop_table :sensors
    drop_table :entry_ways
    drop_table :access_controllers
  end
end
