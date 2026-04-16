class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :uuid
      t.datetime :hw_time
      t.datetime :db_time
      t.string :hw_time_zone
      t.integer :evt_code
      t.string :external_evt_code_text
      t.string :external_evt_code_id
      t.integer :evt_sub_code
      t.string :external_sub_code_text
      t.string :external_sub_code_id
      t.integer :priority
      t.string :data
      t.boolean :consumed, default: false
      t.json :evt_modifiers
      t.json :evt_dev_ref
      t.json :evt_controller_ref
      t.json :evt_cred_ref
      t.json :evt_sched_ref
      t.timestamps
    end
    add_index :events, :uuid, unique: true
    add_index :events, :hw_time
    add_index :events, :evt_code
  end
end
