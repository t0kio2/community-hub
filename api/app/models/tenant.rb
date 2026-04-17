class Tenant < ApplicationRecord
  has_many :tenant_users, dependent: :destroy
end
