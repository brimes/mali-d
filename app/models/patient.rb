class Patient < ApplicationRecord
  has_many :appointments, dependent: :restrict_with_error
  has_many :medical_records, dependent: :destroy

  validates :name, presence: true
  validates :cpf, uniqueness: { allow_blank: true }

  def age
    return nil unless birthdate
    today = Date.current
    today.year - birthdate.year - (today.strftime("%m%d") < birthdate.strftime("%m%d") ? 1 : 0)
  end
end
