class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.string :name
      t.string :job_title
      t.integer :user_id
      t.boolean :active

      t.timestamps
    end
    add_index :employees, :user_id
  end
end
