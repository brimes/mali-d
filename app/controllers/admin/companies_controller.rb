class Admin::CompaniesController < Admin::BaseController
  before_action :set_company, only: [:show, :edit, :update, :destroy]

  def index
    @companies = Company.order(:name)
  end

  def show; end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)
    if @company.save
      redirect_to admin_company_path(@company), notice: "Empresa criada (schema #{@company.subdomain})."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @company.update(company_params.except(:subdomain))
      redirect_to admin_company_path(@company), notice: "Empresa atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @company.destroy
    redirect_to admin_companies_path, notice: "Empresa removida."
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :subdomain, :kind, :status)
  end
end
