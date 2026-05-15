class DashboardController < TenantBaseController
  def show
    @today = Date.current
    @appointments_today = Appointment.on_day(@today).order(:starts_at).includes(:doctor, :patient)
    @doctors_count = Doctor.count
    @patients_count = Patient.count
  end
end
