class StayRoom < ApplicationRecord

	belongs_to :stay_room_type, optional: true

end