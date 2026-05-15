class CreateDoctors < ActiveRecord::Migration[8.1]
  def change
    create_table :doctors do |t|
      t.string :name
      t.string :crm
      t.string :specialty
      t.integer :user_id
      t.boolean :active

      t.timestamps
    end
    add_index :doctors, :user_id
  end
end
