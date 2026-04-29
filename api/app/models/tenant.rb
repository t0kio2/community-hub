class Tenant < ApplicationRecord
  has_many :tenant_members, dependent: :destroy
  has_many :listings, dependent: :destroy

  validates :name, presence: true
  validates :status, presence: true
end
