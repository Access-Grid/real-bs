class AddFlexFieldsToAccessRuleSets < ActiveRecord::Migration[8.0]
  def change
    change_table :access_rule_sets do |t|
      t.string :uuid
      t.integer :priv_type, default: 0
      t.boolean :enabled, default: true
    end
    add_index :access_rule_sets, :uuid, unique: true

    create_table :door_access_priv_elements do |t|
      t.references :access_rule_set, null: false, foreign_key: true
      t.references :door, null: false, foreign_key: { to_table: :devices }
      t.boolean :sched_restriction_invert, default: false

      t.timestamps
    end
  end
end
