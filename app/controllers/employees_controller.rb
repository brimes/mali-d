class EmployeesController < TenantBaseController
  before_action :set_employee, only: [:show, :edit, :update, :destroy]

  def index
    @employees = Employee.order(:name)
  end

  def show; end

  def new
    @employee = Employee.new(active: true)
  end

  def create
    @employee = Employee.new(employee_params)
    if @employee.save
      InviteUserService.new(email: params.dig(:employee, :user_email),
                            name: @employee.name,
                            role: :staff,
                            company: current_company).call_and_link(@employee)
      redirect_to employee_path(@employee), notice: "Funcionário cadastrado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @employee.update(employee_params)
      redirect_to employee_path(@employee), notice: "Atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @employee.destroy
    redirect_to employees_path, notice: "Removido."
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(:name, :job_title, :active)
  end
end
