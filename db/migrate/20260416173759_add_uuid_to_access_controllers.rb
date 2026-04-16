class AddUuidToAccessControllers < ActiveRecord::Migration[8.0]
  def change
    add_column :access_controllers, :uuid, :string
    add_index :access_controllers, :uuid, unique: true
  end
end
