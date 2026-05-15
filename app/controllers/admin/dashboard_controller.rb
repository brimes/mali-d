class Admin::DashboardController < Admin::BaseController
  def index
    @metrics = AdminMetricsService.call
  end
end
