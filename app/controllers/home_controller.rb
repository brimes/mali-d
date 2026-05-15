class HomeController < ApplicationController
  def index
    if admin_host?
      if current_user.admin?
        redirect_to admin_root_path
      else
        redirect_to dashboard_path
      end
    else
      redirect_to dashboard_path
    end
  end
end
