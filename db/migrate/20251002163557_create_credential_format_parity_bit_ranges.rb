class CreateCredentialFormatParityBitRanges < ActiveRecord::Migration[8.0]
  def change
    create_table :credential_format_parity_bit_ranges do |t|
      t.references :credential_format_parity, null: false, foreign_key: true
      t.integer :index
      t.integer :position

      t.timestamps
    end
  end
end
