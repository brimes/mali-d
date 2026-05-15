class Admin::BaseController < ApplicationController
  before_action :require_admin!

  layout "admin"

  private

  def require_admin!
    return if current_user&.admin? && admin_host?

    flash[:alert] = "Acesso restrito ao administrador master."
    redirect_to root_url(subdomain: "app")
  end
end
