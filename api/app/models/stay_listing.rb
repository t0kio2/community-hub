class StayListing < ApplicationRecord
  STAY_TYPES = %w[private_room shared_room entire_place other].freeze

  belongs_to :listing

  validates :listing_id, uniqueness: true
  validates :stay_type, inclusion: { in: STAY_TYPES }, allow_blank: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :price_per_night, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :listing_type_is_stay
  validate :available_period_is_valid

  private

  def listing_type_is_stay
    return if listing.blank? || listing.listing_type == "stay"

    errors.add(:listing, "は宿泊である必要があります")
  end

  def available_period_is_valid
    return if available_from.blank? || available_until.blank? || available_from <= available_until

    errors.add(:available_until, "は開始日以降にしてください")
  end
end
