class PatientsController < TenantBaseController
  before_action :set_patient, only: [:show, :edit, :update, :destroy, :history]

  def index
    @patients = Patient.order(:name)
  end

  def show
    @appointments = @patient.appointments.order(starts_at: :desc).includes(:doctor).limit(20)
  end

  def history
    @records = @patient.medical_records.includes(:doctor, :appointment).order(created_at: :desc)
  end

  def new
    @patient = Patient.new
  end

  def create
    @patient = Patient.new(patient_params)
    if @patient.save
      redirect_to patient_path(@patient), notice: "Paciente cadastrado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @patient.update(patient_params)
      redirect_to patient_path(@patient), notice: "Atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @patient.destroy
    redirect_to patients_path, notice: "Removido."
  end

  private

  def set_patient
    @patient = Patient.find(params[:id])
  end

  def patient_params
    params.require(:patient).permit(:name, :cpf, :birthdate, :phone, :email, :notes)
  end
end
