class TenantUser < ApplicationRecord
  belongs_to :tenant
  belongs_to :account

  validates :role, presence: true, inclusion: { in: %w[owner staff] }
  validates :status, presence: true
end
