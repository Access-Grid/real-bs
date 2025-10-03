class CreateBuildings < ActiveRecord::Migration[8.0]
  def change
    create_table :buildings do |t|
      t.string :name
      t.string :address
      t.string :address_2
      t.string :city
      t.string :region
      t.string :country
      t.string :postal_code

      t.timestamps
    end
  end
end
