class Employee < ApplicationRecord
  validates :name, presence: true
  scope :active, -> { where(active: true) }

  def user
    User.find_by(id: user_id)
  end
end
