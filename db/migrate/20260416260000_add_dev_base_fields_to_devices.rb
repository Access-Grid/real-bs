class AddDevBaseFieldsToDevices < ActiveRecord::Migration[8.0]
  def change
    add_column :devices, :external_id, :string
    add_column :devices, :address, :string
    add_column :devices, :logical_address, :integer
    add_column :devices, :mac_address, :string
    add_column :devices, :port, :integer
    add_column :devices, :speed, :integer
    add_column :devices, :dev_sub_type, :integer
    add_column :devices, :dev_mod, :integer
    add_column :devices, :dev_platform, :integer
    add_column :devices, :dev_use, :integer
    add_column :devices, :time_zone, :string
    add_column :devices, :ignore_daylight_savings, :boolean, default: false
    add_column :devices, :dev_mod_config, :json
  end
end
