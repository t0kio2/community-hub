class Tenant < ApplicationRecord

  belongs_to :primary_tenant_location,
              class_name: "TenantLocation",
              optional: true

  has_many :tenant_locations, dependent: :destroy
  has_many :tenant_members, dependent: :destroy
  has_many :listings, dependent: :destroy

  validates :name, presence: true
  validates :status, presence: true
  validate :primary_location_belongs_to_tenant

  private

  def primary_location_belongs_to_tenant
    return if primary_tenant_location.nil?
    return if primary_tenant_location.tenant_id == id

    errors.add(
      :primary_tenant_location,
      "は同じテナントの拠点を指定してください"
    )
  end

end
