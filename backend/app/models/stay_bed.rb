class StayBed < ApplicationRecord
  belongs_to :stay_room

  validates :name, presence: true, uniqueness: { scope: :stay_room_id }
end
