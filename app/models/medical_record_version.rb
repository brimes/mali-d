class MedicalRecordVersion < ApplicationRecord
  belongs_to :medical_record

  def author
    User.find_by(id: author_id)
  end
end
