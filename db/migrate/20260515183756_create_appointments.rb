class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.references :doctor, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at,   null: false
      t.integer  :status, null: false, default: 0
      t.text     :notes

      t.timestamps
    end
    add_index :appointments, [:doctor_id, :starts_at]
  end
end
