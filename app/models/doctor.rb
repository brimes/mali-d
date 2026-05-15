class Doctor < ApplicationRecord
  has_many :appointments, dependent: :restrict_with_error

  validates :name, presence: true
  validates :crm, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  def user
    User.find_by(id: user_id)
  end
end
