class CreateCredentialFormatParityBits < ActiveRecord::Migration[8.0]
  def change
    create_table :credential_format_parity_bits do |t|
      t.string :kind
      t.string :index

      t.timestamps
    end
  end
end
