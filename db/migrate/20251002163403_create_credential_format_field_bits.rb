class CreateCredentialFormatFieldBits < ActiveRecord::Migration[8.0]
  def change
    create_table :credential_format_field_bits do |t|
      t.integer :index
      t.references :credential_format_field, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
