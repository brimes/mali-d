class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string  :name, null: false
      t.string  :subdomain, null: false
      t.integer :kind, null: false, default: 0
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :companies, :subdomain, unique: true
  end
end
