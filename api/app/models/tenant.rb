class Tenant < ApplicationRecord
  has_many :tenant_users, dependent: :destroy

  validates :name, presence: true
  validates :status, presence: true
end
