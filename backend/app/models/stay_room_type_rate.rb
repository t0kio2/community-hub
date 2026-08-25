class StayRoomTypeRate < ApplicationRecord
  belongs_to :stay_room_type
  belongs_to :stay_rate_plan

  validates :stay_room_type_id, uniqueness: { scope: :stay_rate_plan_id }
  validates :price_per_night_amount,
            numericality: { only_integer: true, greater_than: 0 }
  validates :currency, inclusion: { in: %w[JPY] }
  validate :rate_plan_and_room_type_belong_to_same_listing

  private

  def rate_plan_and_room_type_belong_to_same_listing
    return if stay_room_type.blank? || stay_rate_plan.blank?
    return if stay_room_type.stay_listing_id == stay_rate_plan.stay_listing_id

    errors.add(:stay_room_type, "は料金プランと同じ施設に属している必要があります")
  end
end
