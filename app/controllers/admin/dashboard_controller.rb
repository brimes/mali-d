class Admin::DashboardController < Admin::BaseController
  def index
    @companies_count = Company.count
    @users_count = User.count
    @recent_companies = Company.order(created_at: :desc).limit(5)
  end
end
