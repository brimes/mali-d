admin_email = ENV.fetch("ADMIN_EMAIL", "admin@mali-d.local")
admin_password = ENV.fetch("ADMIN_PASSWORD", "changeme123")

admin = User.find_or_initialize_by(email: admin_email)
admin.assign_attributes(
  name: "Administrador",
  role: :admin,
  password: admin_password,
  password_confirmation: admin_password
)
admin.save!

puts "==> Admin master pronto: #{admin.email} (senha: #{admin_password})"
