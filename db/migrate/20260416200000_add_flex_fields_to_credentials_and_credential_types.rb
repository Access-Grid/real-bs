class AddFlexFieldsToCredentialsAndCredentialTypes < ActiveRecord::Migration[8.0]
  def change
    # Credential: add Flex Cred fields
    change_table :credentials do |t|
      t.string :name
      t.string :uuid
      t.boolean :enabled, default: true
      t.datetime :effective
      t.datetime :expires
      t.json :card_pin
    end
    add_index :credentials, :uuid, unique: true

    # Make person_id and credential_type_id optional (Flex Cred doesn't require them)
    change_column_null :credentials, :person_id, true
    change_column_null :credentials, :credential_type_id, true

    # CredentialType: add Flex CredTemplate fields
    change_table :credential_types do |t|
      t.string :name
      t.string :uuid
      t.integer :priority
      t.json :card_pin_template
    end
    add_index :credential_types, :uuid, unique: true
  end
end
