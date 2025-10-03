class CreateCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :credentials do |t|
      t.references :person, null: false, foreign_key: true
      t.references :credential_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
