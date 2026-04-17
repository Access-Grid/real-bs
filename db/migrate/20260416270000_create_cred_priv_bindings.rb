class CreateCredPrivBindings < ActiveRecord::Migration[8.0]
  def change
    create_table :cred_priv_bindings do |t|
      t.references :credential, null: false, foreign_key: true
      t.references :access_rule_set, foreign_key: true
      t.integer :dev_as_door_access_priv_unid
      t.boolean :sched_restriction_invert, default: false
      t.references :schedule, foreign_key: true
      t.timestamps
    end
  end
end
