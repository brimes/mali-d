class Appointment < ApplicationRecord
  enum :status, { scheduled: 0, confirmed: 1, done: 2, cancelled: 3, no_show: 4 }

  belongs_to :doctor
  belongs_to :patient
  has_one :medical_record, dependent: :destroy

  validates :starts_at, :ends_at, presence: true
  validate  :ends_after_starts
  validate  :no_doctor_conflict

  scope :on_day, ->(day) { where(starts_at: day.beginning_of_day..day.end_of_day) }
  scope :between, ->(from, to) { where(starts_at: from..to) }

  private

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank?
    errors.add(:ends_at, "deve ser após o início") if ends_at <= starts_at
  end

  def no_doctor_conflict
    return if starts_at.blank? || ends_at.blank? || doctor_id.blank?

    conflicting = Appointment.where(doctor_id: doctor_id)
                             .where.not(id: id)
                             .where.not(status: [:cancelled, :no_show])
                             .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
                             .exists?
    errors.add(:base, "Conflito de horário com outra consulta deste médico") if conflicting
  end
end
