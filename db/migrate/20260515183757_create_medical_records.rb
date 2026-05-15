class CreateMedicalRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :medical_records do |t|
      t.references :appointment, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.references :doctor, null: false, foreign_key: true
      t.jsonb :vital_signs
      t.datetime :signed_at
      t.integer :signed_by_id

      t.timestamps
    end
  end
end
