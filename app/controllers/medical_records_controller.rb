class MedicalRecordsController < TenantBaseController
  before_action :set_appointment
  before_action :set_record, only: [:show, :edit, :update, :sign]

  def show; end

  def new
    @record = @appointment.medical_record || MedicalRecord.new(
      appointment: @appointment,
      patient_id: @appointment.patient_id,
      doctor_id: @appointment.doctor_id
    )
    render :edit
  end

  def create
    @record = MedicalRecord.new(record_params.merge(
      appointment: @appointment,
      patient_id: @appointment.patient_id,
      doctor_id: @appointment.doctor_id
    ))
    if @record.save
      redirect_to appointment_medical_record_path(@appointment, @record), notice: "Prontuário salvo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @record.signed?
      flash[:alert] = "Prontuário assinado é imutável. Crie uma nova versão."
      redirect_to(appointment_medical_record_path(@appointment, @record)) and return
    end

    if @record.update(record_params)
      redirect_to appointment_medical_record_path(@appointment, @record), notice: "Atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def sign
    @record.snapshot_version!(current_user)
    @record.sign!(current_user)
    redirect_to appointment_medical_record_path(@appointment, @record), notice: "Prontuário assinado."
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:appointment_id])
  end

  def set_record
    @record = @appointment.medical_record
    redirect_to(new_appointment_medical_record_path(@appointment)) and return if @record.nil?
  end

  def record_params
    params.require(:medical_record).permit(:body, vital_signs: {})
  end
end
