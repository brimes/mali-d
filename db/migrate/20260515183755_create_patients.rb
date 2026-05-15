class CreatePatients < ActiveRecord::Migration[8.1]
  def change
    create_table :patients do |t|
      t.string :name, null: false
      t.string :cpf
      t.date   :birthdate
      t.string :phone
      t.string :email
      t.text   :notes

      t.timestamps
    end
    add_index :patients, :cpf, unique: true, where: "cpf IS NOT NULL"
  end
end
