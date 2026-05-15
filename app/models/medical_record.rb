class MedicalRecord < ApplicationRecord
  belongs_to :appointment
  belongs_to :patient
  belongs_to :doctor
  has_many :versions, class_name: "MedicalRecordVersion", dependent: :destroy
  has_rich_text :body

  validates :body, presence: true

  def signed?
    signed_at.present?
  end

  def sign!(user)
    update!(signed_at: Time.current, signed_by_id: user.id)
  end

  def snapshot_version!(user)
    versions.create!(
      body: body.to_s,
      author_id: user.id,
      created_at_snapshot: Time.current
    )
  end
end
