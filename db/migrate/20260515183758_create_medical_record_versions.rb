class CreateMedicalRecordVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :medical_record_versions do |t|
      t.references :medical_record, null: false, foreign_key: true
      t.text :body
      t.integer :author_id
      t.datetime :created_at_snapshot

      t.timestamps
    end
  end
end
