class AddDoorAccessModifiersToCredentials < ActiveRecord::Migration[8.0]
  def change
    add_column :credentials, :door_access_modifiers, :json
  end
end
