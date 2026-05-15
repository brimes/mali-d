class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!

  helper_method :current_company, :admin_host?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Subdomínio atual da request (nil quando estamos no host raiz ou em subdomínio reservado).
  def current_subdomain
    @current_subdomain ||= begin
      sub = request.subdomains.first
      sub if sub.present? && !Company::RESERVED_SUBDOMAINS.include?(sub)
    end
  end

  # Empresa atual derivada do subdomínio. nil quando admin master.
  def current_company
    @current_company ||= Company.find_by(subdomain: current_subdomain) if current_subdomain
  end

  # Estamos no host do admin master? (subdomínio reservado ou sem subdomínio)
  def admin_host?
    current_subdomain.nil?
  end

  private

  def user_not_authorized
    flash[:alert] = "Você não tem permissão para acessar esta área."
    redirect_back fallback_location: root_path
  end
end
