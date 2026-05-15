class DoctorsController < TenantBaseController
  before_action :set_doctor, only: [:show, :edit, :update, :destroy]

  def index
    @doctors = Doctor.order(:name)
  end

  def show; end

  def new
    @doctor = Doctor.new(active: true)
  end

  def create
    @doctor = Doctor.new(doctor_params)
    if @doctor.save
      InviteUserService.new(email: params.dig(:doctor, :user_email),
                            name: @doctor.name,
                            role: :doctor,
                            company: current_company).call_and_link(@doctor)
      redirect_to doctor_path(@doctor), notice: "Médico cadastrado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @doctor.update(doctor_params)
      redirect_to doctor_path(@doctor), notice: "Atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @doctor.destroy
    redirect_to doctors_path, notice: "Removido."
  end

  private

  def set_doctor
    @doctor = Doctor.find(params[:id])
  end

  def doctor_params
    params.require(:doctor).permit(:name, :crm, :specialty, :active)
  end
end
