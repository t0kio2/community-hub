class StayRoomTypeDailySalesControl < ApplicationRecord
  belongs_to :stay_room_type

  validates :stay_date, presence: true, uniqueness: { scope: :stay_room_type_id }
  validates :sales_limit, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
