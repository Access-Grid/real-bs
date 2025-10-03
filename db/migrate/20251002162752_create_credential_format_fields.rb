class CreateCredentialFormatFields < ActiveRecord::Migration[8.0]
  def change
    create_table :credential_format_fields do |t|
      t.string :name

      t.timestamps
    end
  end
end
