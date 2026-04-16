class AddFlexFieldsToCredentialFormatsAndCreateDataLayouts < ActiveRecord::Migration[8.0]
  def change
    # CredentialFormat: add Flex DataFormat/BinaryFormat fields
    change_table :credential_formats do |t|
      t.string :uuid
      t.integer :data_format_type, default: 1
      t.integer :min_bits
      t.integer :max_bits
      t.boolean :support_reverse_read, default: false
      t.json :elements
    end
    add_index :credential_formats, :uuid, unique: true

    # DataLayout / BasicDataLayout
    create_table :data_layouts do |t|
      t.string :name
      t.string :uuid
      t.integer :layout_type, default: 0
      t.integer :priority
      t.boolean :enabled, default: true
      t.integer :data_format_id

      t.timestamps
    end
    add_index :data_layouts, :uuid, unique: true
    add_foreign_key :data_layouts, :credential_formats, column: :data_format_id
  end
end
