class Listing < ApplicationRecord
  LISTING_TYPES = %w[job stay].freeze
  STATUSES = %w[draft published closed archived].freeze

  belongs_to :tenant
  belongs_to :created_by_tenant_member, class_name: "TenantMember", optional: true
  belongs_to :updated_by_tenant_member, class_name: "TenantMember", optional: true

  has_one :job_listing, dependent: :destroy
  has_one :stay_listing, dependent: :destroy
  has_many :listing_images, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_users, through: :favorites, source: :user

  validates :listing_type, presence: true, inclusion: { in: LISTING_TYPES }
  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
end
