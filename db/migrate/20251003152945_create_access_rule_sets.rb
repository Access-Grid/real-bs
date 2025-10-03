class CreateAccessRuleSets < ActiveRecord::Migration[8.0]
  def change
    create_table :access_rule_sets do |t|
      t.string :name

      t.timestamps
    end
  end
end
