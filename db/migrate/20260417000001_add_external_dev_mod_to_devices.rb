class AddExternalDevModToDevices < ActiveRecord::Migration[8.0]
  def change
    add_column :devices, :external_dev_mod_text, :string
    add_column :devices, :external_dev_mod_id, :string
  end
end
