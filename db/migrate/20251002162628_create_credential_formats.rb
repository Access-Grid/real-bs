class CreateCredentialFormats < ActiveRecord::Migration[8.0]
  def change
    create_table :credential_formats do |t|
      t.string :name
      t.integer :length

      t.timestamps
    end
  end
end
