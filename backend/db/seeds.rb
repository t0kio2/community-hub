# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# AdminAccount の作成（idempotent）
admin_email = ENV.fetch('ADMIN_EMAIL', 'admin@example.com')
admin_password = ENV.fetch('ADMIN_PASSWORD', 'secret123')

AdminAccount.find_or_create_by!(email: admin_email) do |admin|
  admin.password = admin_password
  admin.password_confirmation = admin_password
end

puts "Seed: ensured AdminAccount exists => #{admin_email}"
