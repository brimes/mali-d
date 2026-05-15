class AdminMetricsService
  Metric = Struct.new(:companies, :users, :total_appointments, :appointments_this_month,
                      :total_patients, :total_doctors, :signed_records_this_month,
                      :per_company, keyword_init: true)

  PerCompany = Struct.new(:company, :appointments_this_month, :patients, :doctors,
                          :signed_records_this_month, keyword_init: true)

  def self.call
    public_data = Apartment::Tenant.switch("public") do
      { companies: Company.count, users: User.count }
    end

    per_company = []
    totals = { appts: 0, appts_month: 0, patients: 0, doctors: 0, signed_month: 0 }

    Company.find_each do |company|
      Apartment::Tenant.switch(company.subdomain) do
        appts_month = Appointment.where(starts_at: Time.current.beginning_of_month..Time.current.end_of_month).count
        appts_total = Appointment.count
        patients = Patient.count
        doctors = Doctor.count
        signed_month = MedicalRecord.where(signed_at: Time.current.beginning_of_month..Time.current.end_of_month).count

        per_company << PerCompany.new(
          company: company,
          appointments_this_month: appts_month,
          patients: patients,
          doctors: doctors,
          signed_records_this_month: signed_month
        )

        totals[:appts]        += appts_total
        totals[:appts_month]  += appts_month
        totals[:patients]     += patients
        totals[:doctors]      += doctors
        totals[:signed_month] += signed_month
      end
    rescue Apartment::TenantNotFound => e
      Rails.logger.warn("Tenant #{company.subdomain} not found: #{e.message}")
    end

    Metric.new(
      companies: public_data[:companies],
      users: public_data[:users],
      total_appointments: totals[:appts],
      appointments_this_month: totals[:appts_month],
      total_patients: totals[:patients],
      total_doctors: totals[:doctors],
      signed_records_this_month: totals[:signed_month],
      per_company: per_company.sort_by { |c| -c.appointments_this_month }
    )
  end
end
