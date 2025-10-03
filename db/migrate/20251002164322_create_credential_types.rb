class CreateCredentialTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :credential_types do |t|
      t.string :kind
      t.string :frequency
      t.string :protocol

      t.timestamps
    end
  end
end
