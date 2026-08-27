class StayRoomTypeRateDailyPrice < ApplicationRecord
  belongs_to :stay_room_type_rate

  validates :stay_date, presence: true, uniqueness: { scope: :stay_room_type_rate_id }
  validates :price_amount, numericality: { only_integer: true, greater_than: 0 }
end
