class DashboardController < ApplicationController
  def show
    if current_company.nil?
      redirect_to root_url(subdomain: "app") and return
    end
  end
end
