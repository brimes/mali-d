class User < ApplicationRecord
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  enum :role, { staff: 0, doctor: 1, owner: 2, admin: 99 }

  has_many :memberships, dependent: :destroy
  has_many :companies, through: :memberships

  validates :name, presence: true

  def admin?
    role == "admin"
  end
end
