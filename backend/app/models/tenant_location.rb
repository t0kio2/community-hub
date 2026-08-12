class TenantLocation < ApplicationRecord
  LOCATION_TYPES = %w[headquarters office facility other].freeze

  belongs_to :tenant, inverse_of: :tenant_locations

  has_many :listings, dependent: :restrict_with_error
  has_many :primary_tenants,
           class_name: "Tenant",
           foreign_key: :primary_tenant_location_id,
           inverse_of: :primary_tenant_location,
           dependent: :restrict_with_error

  validates :name,
            presence: true,
            length: { maximum: 100 },
            uniqueness: { scope: :tenant_id }
  validates :location_type, presence: true, inclusion: { in: LOCATION_TYPES }
  validates :postal_code, length: { maximum: 16 }, allow_blank: true
  validates :prefecture, length: { maximum: 50 }, allow_blank: true
  validates :city, length: { maximum: 100 }, allow_blank: true
  validates :address_line1, length: { maximum: 255 }, allow_blank: true
  validates :address_line2, length: { maximum: 255 }, allow_blank: true
  validates :latitude,
            presence: true,
            numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude,
            presence: true,
            numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  def full_address
    [postal_code, prefecture, city, address_line1, address_line2].compact_blank.join(" ")
  end
end
