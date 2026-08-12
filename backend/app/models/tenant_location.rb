class TenantLocation < ApplicationRecord
    belongs_to :tenant

    has_many :listings, dependent: :restrict_with_error
    has_many :primary_tenants,
							class_name: "Tenant",
							foreign_key: :primary_tenant_location_id,
							inverse_of: :primary_tenant_location,
							dependent: :restrict_with_error
            
end