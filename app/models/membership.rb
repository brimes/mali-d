class Membership < ApplicationRecord
  enum :role, { staff: 0, doctor: 1, owner: 2 }

  belongs_to :user
  belongs_to :company

  validates :user_id, uniqueness: { scope: :company_id }
end
