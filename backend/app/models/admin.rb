class Admin < ApplicationRecord
  ROLES = %w[super_admin operator].freeze

  belongs_to :account

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :status, presence: true
end
