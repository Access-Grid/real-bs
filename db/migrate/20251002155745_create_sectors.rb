class CreateSectors < ActiveRecord::Migration[8.0]
  def change
    create_table :sectors do |t|
      t.string :name
      t.references :building, null: false, foreign_key: true
      t.references :parent, null: true, foreign_key: { to_table: :sectors }

      t.timestamps
    end
  end
end
