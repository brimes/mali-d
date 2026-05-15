class AppointmentsController < TenantBaseController
  before_action :set_appointment, only: [:show, :edit, :update, :destroy]

  def index
    respond_to do |format|
      format.html
      format.json do
        from = Time.zone.parse(params[:start]) rescue Time.current.beginning_of_month
        to   = Time.zone.parse(params[:end])   rescue Time.current.end_of_month
        scope = Appointment.between(from, to).includes(:doctor, :patient)
        scope = scope.where(doctor_id: params[:doctor_id]) if params[:doctor_id].present?
        render json: scope.map { |a| event_for(a) }
      end
    end
  end

  def show; end

  def new
    @appointment = Appointment.new(starts_at: params[:start], ends_at: params[:end])
  end

  def create
    @appointment = Appointment.new(appointment_params)
    if @appointment.save
      respond_to do |format|
        format.html { redirect_to appointment_path(@appointment), notice: "Consulta agendada." }
        format.json { render json: event_for(@appointment), status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @appointment.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @appointment.update(appointment_params)
      redirect_to appointment_path(@appointment), notice: "Atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @appointment.destroy
    redirect_to appointments_path, notice: "Removida."
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(:doctor_id, :patient_id, :starts_at, :ends_at, :status, :notes)
  end

  def event_for(appt)
    {
      id: appt.id,
      title: "#{appt.patient.name} · Dr(a). #{appt.doctor.name}",
      start: appt.starts_at.iso8601,
      end: appt.ends_at.iso8601,
      url: appointment_path(appt),
      backgroundColor: status_color(appt.status),
      borderColor: status_color(appt.status)
    }
  end

  def status_color(status)
    {
      "scheduled" => "#3b82f6",
      "confirmed" => "#10b981",
      "done"      => "#6366f1",
      "cancelled" => "#ef4444",
      "no_show"   => "#9ca3af"
    }[status] || "#3b82f6"
  end
end
