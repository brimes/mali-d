class InviteUserService
  attr_reader :email, :name, :role, :company, :generated_password

  def initialize(email:, name:, role:, company:)
    @email = email.to_s.strip.downcase
    @name = name
    @role = role
    @company = company
  end

  # Creates User (public schema) + Membership, then links tenant record via user_id.
  def call_and_link(tenant_record)
    return if email.blank?

    user = Apartment::Tenant.switch("public") do
      existing = User.find_by(email: email)
      next existing if existing

      @generated_password = SecureRandom.alphanumeric(12)
      User.create!(
        email: email,
        name: name,
        role: role,
        password: @generated_password,
        password_confirmation: @generated_password
      )
    end

    Apartment::Tenant.switch("public") do
      Membership.find_or_create_by!(user: user, company: company) do |m|
        m.role = role_to_membership_role(role)
      end
    end

    tenant_record.update_column(:user_id, user.id) if tenant_record.respond_to?(:user_id)
    Rails.logger.info("Invite: #{email} senha=#{@generated_password}") if @generated_password
    user
  end

  private

  def role_to_membership_role(r)
    case r.to_sym
    when :owner then :owner
    when :doctor then :doctor
    else :staff
    end
  end
end
