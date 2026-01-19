class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :role, inclusion: { in: %w[user provider admin] }
  validates :status, inclusion: { in: %w[active suspended] }
end
