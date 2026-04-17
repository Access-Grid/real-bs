class AddDevConfigToDevices < ActiveRecord::Migration[8.0]
  def change
    add_column :devices, :dev_config, :json
  end
end
