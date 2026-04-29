class TenantMember < ApplicationRecord
  belongs_to :tenant
  belongs_to :account

  has_many :created_listings,
           class_name: "Listing",
           foreign_key: :created_by_tenant_member_id,
           dependent: :nullify,
           inverse_of: :created_by_tenant_member
  has_many :updated_listings,
           class_name: "Listing",
           foreign_key: :updated_by_tenant_member_id,
           dependent: :nullify,
           inverse_of: :updated_by_tenant_member

  validates :role, presence: true, inclusion: { in: %w[owner staff] }
  validates :status, presence: true
end
