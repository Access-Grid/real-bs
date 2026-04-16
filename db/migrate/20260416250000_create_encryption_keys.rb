class CreateEncryptionKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :encryption_keys do |t|
      t.string :uuid
      t.string :algorithm
      t.integer :size
      t.string :key_identifier
      t.text :bytes
      t.timestamps
    end
    add_index :encryption_keys, :uuid, unique: true
  end
end
