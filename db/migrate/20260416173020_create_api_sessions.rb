class CreateApiSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :api_sessions do |t|
      t.string :session_token, null: false
      t.references :user, null: false, foreign_key: true
      t.datetime :expires_at, null: false
      t.integer :api_client_type

      t.timestamps
    end
    add_index :api_sessions, :session_token, unique: true
  end
end
