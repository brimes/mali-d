class TenantBaseController < ApplicationController
  before_action :require_tenant!
  before_action :require_membership!

  helper_method :current_membership

  private

  def require_tenant!
    return if current_company.present?

    redirect_to root_url(subdomain: "app") and return
  end

  def require_membership!
    return if current_user.admin?
    return if current_membership.present?

    flash[:alert] = "Você não tem acesso a esta empresa."
    redirect_to root_url(subdomain: "app")
  end

  def current_membership
    @current_membership ||= current_user.memberships.find_by(company_id: current_company.id)
  end
end
