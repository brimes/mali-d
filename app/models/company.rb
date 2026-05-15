class Company < ApplicationRecord
  RESERVED_SUBDOMAINS = %w[app www admin api root public].freeze
  SUBDOMAIN_FORMAT = /\A[a-z0-9][a-z0-9-]{1,30}[a-z0-9]\z/

  enum :kind,   { clinic: 0, office: 1, hospital: 2, doctor_pj: 3 }
  enum :status, { active: 0, suspended: 1 }

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  validates :name, presence: true
  validates :subdomain,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: SUBDOMAIN_FORMAT, message: "deve ter apenas letras minúsculas, números e hífens" },
            exclusion: { in: RESERVED_SUBDOMAINS, message: "é reservado" }

  before_validation :normalize_subdomain

  after_create  :create_tenant_schema
  after_destroy :drop_tenant_schema

  private

  def normalize_subdomain
    self.subdomain = subdomain.to_s.downcase.strip
  end

  def create_tenant_schema
    Apartment::Tenant.create(subdomain)
  rescue Apartment::TenantExists
    Rails.logger.warn("Tenant schema #{subdomain} already exists")
  end

  def drop_tenant_schema
    Apartment::Tenant.drop(subdomain)
  rescue Apartment::TenantNotFound
    Rails.logger.warn("Tenant schema #{subdomain} not found on drop")
  end
end
