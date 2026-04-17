class AddExternalIdToAccessRuleSetsAndRemoveCredTypeExtras < ActiveRecord::Migration[8.0]
  def change
    add_column :access_rule_sets, :external_id, :string
    remove_column :credential_types, :kind, :string
    remove_column :credential_types, :frequency, :string
    remove_column :credential_types, :protocol, :string
  end
end
