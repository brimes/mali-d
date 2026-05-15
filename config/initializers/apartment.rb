require "apartment/elevators/subdomain"

RESERVED_TENANT_SUBDOMAINS = %w[app www admin api root public].freeze

Apartment.configure do |config|
  # Modelos globais que vivem no schema `public`.
  config.excluded_models = %w[User Company Membership]

  # Tenants são derivados das empresas cadastradas.
  config.tenant_names = lambda do
    if ActiveRecord::Base.connection.data_source_exists?("companies")
      Company.pluck(:subdomain)
    else
      []
    end
  end

  config.use_schemas = true
  config.persistent_schemas = %w[shared_extensions]
end

Apartment::Elevators::Subdomain.excluded_subdomains = RESERVED_TENANT_SUBDOMAINS

Rails.application.config.middleware.use Apartment::Elevators::Subdomain
