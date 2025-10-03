class CreateAccessControllers < ActiveRecord::Migration[8.0]
  def change
    create_table :access_controllers do |t|
      t.string :name
      t.string :model
      t.string :brand
      t.json :metadata
      t.json :public_metadata
      t.references :sector, null: false, foreign_key: true
      t.boolean :is_virtual

      t.timestamps
    end
  end
end
