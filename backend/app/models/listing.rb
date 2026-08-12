class Listing < ApplicationRecord
  LISTING_TYPES = %w[job stay].freeze
  STATUSES = %w[draft published closed archived].freeze

  belongs_to :tenant
  belongs_to :tenant_location, optional: true

  belongs_to :created_by_tenant_member,
             class_name: "TenantMember",
             optional: true,
             inverse_of: :created_listings
  belongs_to :updated_by_tenant_member,
             class_name: "TenantMember",
             optional: true,
             inverse_of: :updated_listings

  has_one :job_listing, dependent: :destroy
  has_one :stay_listing, dependent: :destroy

  has_many :listing_images, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_users, through: :favorites, source: :user

  validates :listing_type, presence: true, inclusion: { in: LISTING_TYPES }
  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :location_belongs_to_tenant

  private
  def location_belongs_to_tenant
    return if tenant_location.nil?
    return if tenant_location.tenant_id == tenant_id

    errors.add(
      :tenant_location,
      "は同じテナントの拠点を指定してください"
    )
  end

end
