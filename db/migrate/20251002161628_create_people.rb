class CreatePeople < ActiveRecord::Migration[8.0]
  def change
    create_table :people do |t|
      t.string :first_name
      t.string :last_name
      t.string :title
      t.string :phone_number
      t.string :email
      t.references :group, null: false, foreign_key: true
      t.json :metadata

      t.timestamps
    end
  end
end
