# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

admin_email = ENV.fetch('ADMIN_EMAIL', 'admin@example.com')
admin_password = ENV.fetch('ADMIN_PASSWORD', 'secret123')

admin_account = AdminAccount.find_by(email: admin_email)

if admin_account
  raise "Admin is missing for #{admin_email}" unless admin_account.admin
else
  admin_account = AdminAccounts::CreateService.new(
    account_attributes: {
      email: admin_email,
      password: admin_password,
      password_confirmation: admin_password
    },
    role: "super_admin"
  ).call.account
end

puts "Seed: ensured AdminAccount exists => #{admin_email}"
